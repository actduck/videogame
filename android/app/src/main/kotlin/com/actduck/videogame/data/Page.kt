package com.actduck.videogame.data

class Page<T>(
  val content: List<T>,
  val totalPages: Int?,
  val totalElements: Int?,
  val last: Boolean?,
  val number: Int?,
  val size: Int?,
  val first: Boolean?,
  val empty: Boolean?
)