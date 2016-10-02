package wiki

import grails.plugin.springcache.annotations.*

class ContentController extends BaseWikiController {
    static allowedMethods = [saveWikiPage: "POST", rollbackWikiVersion: "POST"]

    def wikiPageService

    def index() {

        def wikiPage = wikiPageService.getCachedOrReal()

         if (request.xhr) {
                render template: "wikiShow", model: [content: wikiPage, update: params._ul, latest: 1.0]
            } else {
                // disable comments
                render view: "contentPage", model: [content: wikiPage, latest: 1.0]
            }
        }
    }