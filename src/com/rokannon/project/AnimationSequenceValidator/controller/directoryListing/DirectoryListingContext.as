package com.rokannon.project.AnimationSequenceValidator.controller.directoryListing
{
    import flash.filesystem.File;

    public class DirectoryListingContext
    {
        public const directoryListing:Vector.<File> = new <File>[];

        public var directoryToLoad:File;

        public function DirectoryListingContext()
        {
        }
    }
}