package com.actduck.videogame.util;

import android.os.Environment;
import android.os.StatFs;
import java.io.File;

public class StorageUtils {
  public static boolean externalMemoryAvailable() {
    return Environment.getExternalStorageState().equals(
        Environment.MEDIA_MOUNTED);
  }

  public static String getAvailableInternalMemorySize() {
    File path = Environment.getDataDirectory();
    StatFs stat = new StatFs(path.getPath());
    long blockSize = stat.getBlockSizeLong();
    long availableBlocks = stat.getAvailableBlocksLong();
    return formatSize(availableBlocks * blockSize);
  }

  public static String getTotalInternalMemorySize() {
    File path = Environment.getDataDirectory();
    StatFs stat = new StatFs(path.getPath());
    long blockSize = stat.getBlockSizeLong();
    long totalBlocks = stat.getBlockCountLong();
    return formatSize(totalBlocks * blockSize);
  }

  public static Long getAvailableExternalMemorySize() {
    if (externalMemoryAvailable()) {
      File path = Environment.getExternalStorageDirectory();
      StatFs stat = new StatFs(path.getPath());
      long blockSize = stat.getBlockSizeLong();
      long availableBlocks = stat.getAvailableBlocksLong();
      return availableBlocks * blockSize;
    } else {
      return 0L;
    }
  }

  public static Long getTotalExternalMemorySize() {
    if (externalMemoryAvailable()) {
      File path = Environment.getExternalStorageDirectory();
      StatFs stat = new StatFs(path.getPath());
      long blockSize = stat.getBlockSizeLong();
      long totalBlocks = stat.getBlockCountLong();
      return totalBlocks * blockSize;
    } else {
      return 0L;
    }
  }

  public static String formatSize(long size) {
    String suffix = null;

    if (size >= 1024) {
      suffix = "KB";
      size /= 1024;
      if (size >= 1024) {
        suffix = "MB";
        size /= 1024;
        if (size >= 1024) {
          suffix = "GB";
          size /= 1024;
        }
      }
    }

    StringBuilder resultBuffer = new StringBuilder(Long.toString(size));

    int commaOffset = resultBuffer.length() - 3;
    while (commaOffset > 0) {
      resultBuffer.insert(commaOffset, ',');
      commaOffset -= 3;
    }

    if (suffix != null) resultBuffer.append(suffix);
    return resultBuffer.toString();
  }
}
