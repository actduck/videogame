package com.actduck.videogame.data.source.remote

import java.io.Serializable

data class ApiResponse<T>(
  val code: Int,
  val data: T? = null,
  val msg: String? = null

) : Serializable {
  companion object {
    private const val RESULT_OK = 0
    private const val RESULT_FAIL = 1

    fun <T> success(t: T): ApiResponse<T> {
      return ApiResponse(RESULT_OK, t, "success")
    }

    fun <T> fail(msg: String): ApiResponse<T> {
      return ApiResponse(RESULT_FAIL, msg = msg)
    }
  }

  fun isSuccessful(): Boolean {
    return code == RESULT_OK
  }

}

class MyApiException(msg: String?) : RuntimeException(msg)