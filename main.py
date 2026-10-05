import os

# The decky plugin module is located at decky-loader/plugin
# For easy intellisense checkout the decky-loader code repo
# and add the `decky-loader/plugin/imports` path to `python.analysis.extraPaths` in `.vscode/settings.json`
import decky
import asyncio
import subprocess
from functools import wraps
from subprocess import TimeoutExpired, CalledProcessError

GAMESCOPE_ENV = os.environ.copy() | {'GAMESCOPE_WAYLAND_DISPLAY':'gamescope-0', 'LD_LIBRARY_PATH': '', 'XDG_RUNTIME_DIR': ''}

GAMESCOPE_PATH = os.path.join('/', 'usr', 'bin', 'gamescope')
GAMESCOPE_HOMEBREW_PATH = os.path.join(decky.DECKY_PLUGIN_DIR,'bin','src','gamescope')
GAMESCOPE_HOMEBREW_WRAPPER_PATH = os.path.join(decky.DECKY_PLUGIN_DIR, 'gamescope')


def subprocess_run(command: list[str], env: dict[str,str] = GAMESCOPE_ENV) -> bool:
    output = {}
    try:
        decky.logger.info(f"Before: {' '.join(command)}")
        output = subprocess.run(command, text=True, capture_output=True, check=True, timeout=2, env=env) 
        decky.logger.info(f"After: {' '.join(command)}: {output}")
        return not output.returncode
    except TimeoutExpired:
        decky.logger.info(f"Timeout expired {' '.join(command)}")
    except CalledProcessError as e:
        decky.logger.info(f"process execution error {e}")
        decky.logger.info(f"error: {e.returncode} : {e.stderr}")
        decky.logger.info(e)
    except Exception as e:
        decky.logger.info(f"Exception: {e}")

    decky.logger.info(f"Some error happened during {''.join(command)}")
    return False
    
    
class Plugin:
    async def LOGGER(self, value: str) -> None:
        decky.logger.info(f'[FRONTEND] {value}')
        pass
    
    async def enable_gamescope(self) -> bool:
        create: bool = await self._create_gamescope_wrapper()
        mount: bool = await self._mount_gamescope()
        decky.logger.info(f"[BACKEND] create:{create} mount:{mount} return: {create and mount}")
        return create and mount
        
        # return await self._create_gamescope_wrapper() and await self._mount_gamescope()

    async def _create_gamescope_wrapper(self) -> bool:
        if os.path.exists(GAMESCOPE_HOMEBREW_WRAPPER_PATH):
            return True
        try:
            decky.logger.info("[BACKEND] writing gamescope wrapper")
            wrapper_string = (
                '#!/usr/bin/env bash\n'
                'export GAMESCOPE_WAYLAND_DISPLAY=gamescope-0\n'
                f'exec {GAMESCOPE_HOMEBREW_PATH} "$@"')
            with open(GAMESCOPE_HOMEBREW_WRAPPER_PATH, mode='w', encoding='utf-8') as file:
                file.write(wrapper_string)
            os.chmod(GAMESCOPE_HOMEBREW_WRAPPER_PATH, mode=0o755)
            decky.logger.info("[BACKEND] done writing gamescope")
        except Exception as e:
            decky.logger.info("[BACKEND] Unable to create gamescope wrapper script: %s", e)
            return False
        
    async def _mount_gamescope(self) -> bool:
        decky.logger.info("mounting gamescope")
        return subprocess_run(['mount', '--bind', GAMESCOPE_HOMEBREW_WRAPPER_PATH, GAMESCOPE_PATH])

    async def unmount_gamescope(self) -> bool:
        decky.logger.info("unmounting gamescope")
        return subprocess_run(['umount', GAMESCOPE_PATH])

    async def is_pip_mounted(self) -> bool:
        return self.gamescope_mounted

    # Asyncio-compatible long-running code, executed in a task when the plugin is loaded
    async def _main(self):
        self.loop = asyncio.get_event_loop()
        decky.logger.info(f'LOG_LEVEL: {os.environ.get("LOG_LEVEL")}')
        # test if gamescope is mounted and set "gamescope installed"
        self.gamescope_mounted = await self._is_gamescope_mounted()
        # if mounted return else do wrapper then mount
        if not self.gamescope_mounted:
            decky.logger.info("[BACKEND] before enable gamescope")
            await self.enable_gamescope()
        decky.logger.info(f"[BACKEND] mounted: {self.gamescope_mounted}")
        
    # Function called first during the unload process, utilize this to handle your plugin being stopped, but not
    # completely removed
    async def _unload(self):
        decky.logger.info("Goodnight World!")
        pass

    # Function called after `_unload` during uninstall, utilize this to clean up processes and other remnants of your
    # plugin that may remain on the system
    async def _uninstall(self):
        decky.logger.info("Removing gamescope override")

        await self.unmount_gamescope()

    async def _is_gamescope_mounted(self) -> bool:
        return subprocess_run(['findmnt', '-M', GAMESCOPE_PATH, '-f'])

    async def micro_sleep(self, duration: float = 1):
        await asyncio.sleep(.2)
        pass
    
    # Migrations that should be performed before entering `_main()`.
    async def _migration(self):
        pass
