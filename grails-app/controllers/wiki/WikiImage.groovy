package wiki

class WikiImage {
    String name

    static constraints = {
        name blank: false, unique: true
    }

    static mapping = {
        cache true
        name index: true
        image fetch: "join"
    }
}
