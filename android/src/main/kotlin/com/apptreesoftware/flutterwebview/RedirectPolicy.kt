package com.apptreesoftware.flutterwebview

enum class MatchType {
    PREFIX,
    SUFFIX,
    FULL_URL
}

data class RedirectPolicy(val url : String,
                          val stopOnRedirect : Boolean,
                          val matchType : MatchType)