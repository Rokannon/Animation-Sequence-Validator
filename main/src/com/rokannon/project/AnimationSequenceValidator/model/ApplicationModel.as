package com.rokannon.project.AnimationSequenceValidator.model
{
    import com.rokannon.core.command.CommandExecutor;

    import flash.filesystem.File;

    public class ApplicationModel
    {
        public const commandExecutor:CommandExecutor = new CommandExecutor();
        public const filesToLoad:Vector.<File> = new <File>[];
        public const frameInfos:Vector.<FrameInfo> = new <FrameInfo>[];
        public const configData:ConfigData = new ConfigData();

        public var numLoadedFiles:int = 0;

        public function ApplicationModel()
        {
        }

        public function validateFiles(files:Vector.<File>):Boolean
        {
            var numDirectories:int = 0;
            for each (var file:File in files)
                if (file.isDirectory)
                    ++numDirectories;
            // All files are non-directories or a single directory.
            return files.length > 0 && !(files.length > 1 && numDirectories > 0);
        }

        public function getColorFromString(string:String):uint
        {
            if (string.charAt(0) == "#")
                string = string.substr(1);
            return parseInt(string, 16);
        }
    }
}