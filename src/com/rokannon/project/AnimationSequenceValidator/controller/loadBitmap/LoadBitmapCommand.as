package com.rokannon.project.AnimationSequenceValidator.controller.loadBitmap
{
    import com.rokannon.core.command.CommandBase;

    import flash.display.Bitmap;

    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;

    public class LoadBitmapCommand extends CommandBase
    {
        private const _loader:Loader = new Loader();

        private var _context:LoadBitmapContext;

        public function LoadBitmapCommand(context:LoadBitmapContext)
        {
            super();
            _context = context;
        }

        override protected function onStart():void
        {
            _loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
            _loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            _loader.loadBytes(_context.bytesToLoad);
        }

        private function onLoaderComplete(event:Event):void
        {
            _loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
            _loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            _context.bitmap = event.target.content as Bitmap;
            onComplete();
        }

        private function onLoaderError(event:IOErrorEvent):void
        {
            _loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
            _loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            onFailed();
        }
    }
}