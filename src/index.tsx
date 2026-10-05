import {
  ButtonItem,
  PanelSection,
  PanelSectionRow,
  staticClasses,
  Toggle
} from "@decky/ui";
import {
  removeEventListener,
  callable,
  definePlugin,
  // routerHook
} from "@decky/api"
import { useState, useEffect } from "react";
import { FaShip } from "react-icons/fa";

// import logo from "../assets/logo.png";
const logger = callable<[string], void>("LOGGER");

const is_gamescope_pip_mounted = callable<[], boolean>("is_pip_mounted");

function Content() {
  const [pipMounted, setPipMounted] = useState<boolean>(false);

  useEffect(() => {
    const fetchData = async () => {
      const is_mounted = await is_gamescope_pip_mounted();
      await logger(`mounted:${is_mounted}`);
      setPipMounted(is_mounted);
    };
    fetchData();
  }, []);

  return (
    <PanelSection title="Gamescope State">

      <PanelSectionRow>
      <div>Gamescope Binary may require a reboot after initial plugin install</div>
      <div>{pipMounted ? "TRUE" : "FALSE"}</div>
      </PanelSectionRow>
    </PanelSection>
  );
};

export default definePlugin(() => {
  console.log("Gamescope-Custom starting...")
 
    // serverApi.routerHook.addRoute("/decky-plugin-test", DeckyPluginRouterTest, {
  //   exact: true,
  // });

  // Add an event listener to the "timer_event" event from the backend
  return {
    // The name shown in various decky menus
    name: "Gamescope-Custom",
    // The element displayed at the top of your plugin's menu
    titleView: <div className={staticClasses.Title}>Gamescope Custom Binary</div>,
    // The content of your plugin's menu
    content: <Content />,
    // The icon displayed in the plugin list
    icon: <FaShip />,
    // The function triggered when your plugin unloads
    onDismount() {
      console.log("Unloading Gamescope-Custom")
      removeEventListener("timer_event", listener);
      // serverApi.routerHook.removeRoute("/decky-plugin-test");
    },
  };
});
