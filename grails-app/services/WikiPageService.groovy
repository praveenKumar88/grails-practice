import grails.plugin.cache.CacheEvict
import grails.plugin.cache.Cacheable
import grails.transaction.NotTransactional
import grails.transaction.Transactional
import wiki.Content
import wiki.User
import wiki.Version
import wiki.WikiPage
import wiki.WikiPageUpdateEvent

import javax.persistence.OptimisticLockException
import java.util.concurrent.ConcurrentLinkedQueue

/*
 * author: Matthew Taylor
 */

@Transactional
class WikiPageService {
    def cacheService
    def searchableService
    def wikiPageUpdates = new ConcurrentLinkedQueue<WikiPageUpdateEvent>()

    @Cacheable(value = "content", key = "#title")
    @NotTransactional
    def getCachedOrReal() {
        return "praveen"
    }

    @NotTransactional
    def pageChanged(id) {
        id = id.decodeURL()
        cacheService.removeContent(id)
    }

    @CacheEvict(value = "content", key = "#title")
    WikiPage createOrUpdateWikiPage(String title, String body, User user, Long version = null) {
        def page = WikiPage.findByTitle(title)
        if (page) {
            return updateContent(page, body, user, version)
        } else {
            page = new WikiPage(title: title, body: body)
            return createContent(page, user)
        }
    }

    protected def createContent(Content content, User user) {
        if (content.locked == null) content.locked = false
        content.save(flush: true)
        if (!content.hasErrors()) {
            Version v = content.createVersion()
            v.author = user
            v.save(failOnError: true)

            wikiPageUpdates << new WikiPageUpdateEvent(this, content.title, content.getClass().name)
        }

        return content
    }

    protected def updateContent(Content content, String body, User user, Long version) {
        if (content.version != version) {
            throw new OptimisticLockException("Content [${content.class.simpleName}:${content.id}] was updated by someone else. Version mismatch: Submitted version ($version), Content version (${content.version}).")
        } else if (content.body != body) {
            content.body = body
            content.lock()
            content.version = content.version + 1
            content.save(flush: true, failOnError: true)

            if (!content.hasErrors()) {
                Version v = content.createVersion()
                v.author = user
                v.save(failOnError: true)

                wikiPageUpdates << new WikiPageUpdateEvent(this, content.title, content.getClass().name)
                
                evictFromCache(content.id, content.title)
            }
        }
        
        return content
    }

    def Version latestVersion(Content content) {

    }

    private evictFromCache(id, title) {
        cacheService.removeWikiText(title)
        cacheService.removeContent(title)
        
        if (id) cacheService.removeCachedText('versionList' + id)
    }
    }
