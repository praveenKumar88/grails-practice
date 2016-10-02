package wiki

class User {
    String email
    String login
    String password
    Boolean enabled = true

    static hasMany = [roles: Role, permissions: String]

    static constraints = {
        email email: true, unique: true, blank: false
        login blank: false, size: 5..15
        password blank: false, nullable: false, display: false
    }

    static mapping = {
        cache true
    }

    String toString() {
        login
    }
}
