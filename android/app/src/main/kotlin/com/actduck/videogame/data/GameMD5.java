package com.actduck.videogame.data;

import java.io.Serializable;

public class GameMD5 implements Serializable {

  public Long id = 0L;

  public String zipRom;
  public int splitCount;

  // 用逗号分隔
  public String splitRoms;
}

