//
// Created by consti10 on 17.02.23.
//

#include "openhd_config.h"
#include "openhd_spdlog.h"
#include "openhd_util.h"
#include "openhd_util_filesystem.h"

#include "../lib/ini/ini.hpp"

static std::string CONFIG_FILE_PATH="/boot/openhd/hardware.config";

static std::shared_ptr<spdlog::logger> get_logger(){
  return openhd::log::create_or_get("config");
}

void openhd::set_config_file(const std::string &config_file_path) {
    get_logger()->debug("Using custom config file path [{}]",config_file_path);
    CONFIG_FILE_PATH=config_file_path;
}

static openhd::Config load_or_default(){
    try{
      openhd::Config ret{};
      if(!OHDFilesystemUtil::exists(CONFIG_FILE_PATH)){
        get_logger()->warn("Config file [{}] does not exist, using default settings",CONFIG_FILE_PATH);
        return ret;
      }
      inih::INIReader r{CONFIG_FILE_PATH};
      // Get and parse the ini value
      ret.WIFI_ENABLE_AUTODETECT = r.Get<bool>("wifi", "WIFI_ENABLE_AUTODETECT");
      ret.WIFI_WB_LINK_CARDS = r.GetVector<std::string>("wifi", "WIFI_WB_LINK_CARDS");
      ret.WIFI_WIFI_HOTSPOT_CARD = r.Get<std::string>("wifi", "WIFI_WIFI_HOTSPOT_CARD");

      ret.CAMERA_ENABLE_AUTODETECT = r.Get<bool>("camera", "CAMERA_ENABLE_AUTODETECT");
      ret.CAMERA_N_CAMERAS = r.Get<int>("camera", "CAMERA_N_CAMERAS");
      ret.CAMERA_CAMERA0_TYPE = r.Get<std::string>("camera", "CAMERA_CAMERA0_TYPE");
      ret.CAMERA_CAMERA1_TYPE = r.Get<std::string>("camera", "CAMERA_CAMERA1_TYPE");

      ret.NW_ETHERNET_CARD = r.Get<std::string>("network", "NW_ETHERNET_CARD");
      ret.NW_MANUAL_FORWARDING_IPS =  r.GetVector<std::string>("network", "NW_MANUAL_FORWARDING_IPS");
      ret.NW_FORWARD_TO_LOCALHOST_58XX = r.Get<bool>("network","NW_FORWARD_TO_LOCALHOST_58XX");

      ret.GEN_ENABLE_LAST_KNOWN_POSITION =r.Get<bool>("generic","GEN_ENABLE_LAST_KNOWN_POSITION");
      return ret;
    }catch (std::exception& exception){
      get_logger()->error("Ill-formatted config file {}",std::string(exception.what()));
    }
    return {};
}

openhd::Config openhd::load_config() {
    static openhd::Config config=load_or_default();
    return config;
}

void openhd::debug_config(const openhd::Config& config) {
  get_logger()->debug("WIFI_ENABLE_AUTODETECT:{}, WIFI_WB_LINK_CARDS:{}, WIFI_WIFI_HOTSPOT_CARD:{},\n"
      "CAMERA_ENABLE_AUTODETECT:{}, CAMERA_N_CAMERAS:{}, CAMERA_CAMERA0_TYPE:{}, CAMERA_CAMERA1_TYPE:{}\n"
      "NW_MANUAL_FORWARDING_IPS:{},NW_ETHERNET_CARD:{},NW_FORWARD_TO_LOCALHOST_58XX:{}",
      config.WIFI_ENABLE_AUTODETECT,OHDUtil::str_vec_as_string(config.WIFI_WB_LINK_CARDS),config.WIFI_WIFI_HOTSPOT_CARD,
      config.CAMERA_ENABLE_AUTODETECT,config.CAMERA_N_CAMERAS,config.CAMERA_CAMERA0_TYPE,config.CAMERA_CAMERA1_TYPE,
      OHDUtil::str_vec_as_string(config.NW_MANUAL_FORWARDING_IPS),config.NW_ETHERNET_CARD,config.NW_FORWARD_TO_LOCALHOST_58XX
      );
}

void openhd::debug_config() {
  auto config=load_config();
  debug_config(config);
}

bool openhd::nw_ethernet_card_manual_active(const openhd::Config &config) {
  if(OHDUtil::contains(config.NW_ETHERNET_CARD,RPI_ETHERNET_ONLY)){
	return false;
  }
  return true;
}
