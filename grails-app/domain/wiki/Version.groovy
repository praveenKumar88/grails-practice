package wiki

class Version extends Content {
    Integer number
    Content current
    User author

    static mapping = {
        cache usage:'read-only'
    }
}
