package com.rokannon.project.AnimationSequenceValidator.controller.loadFrameInfo
{
    import com.rokannon.command.bitmapLoad.BitmapLoadCommand;
    import com.rokannon.command.bitmapLoad.BitmapLoadContext;
    import com.rokannon.command.fileLoad.FileLoadCommand;
    import com.rokannon.command.fileLoad.FileLoadContext;
    import com.rokannon.core.command.MethodCommand;
    import com.rokannon.core.command.SequenceCommand;
    import com.rokannon.project.AnimationSequenceValidator.controller.readFrameType.ReadFrameTypeCommand;
    import com.rokannon.project.AnimationSequenceValidator.controller.readFrameType.ReadFrameTypeContext;

    public class LoadFrameInfoCommand extends SequenceCommand
    {
        private const _fileLoadContext:FileLoadContext = new FileLoadContext();
        private const _loadBitmapContext:BitmapLoadContext = new BitmapLoadContext();
        private const _readFrameTypeContext:ReadFrameTypeContext = new ReadFrameTypeContext();

        private var _context:LoadFrameInfoContext;

        public function LoadFrameInfoCommand(context:LoadFrameInfoContext)
        {
            super();
            _context = context;
            _fileLoadContext.fileToLoad = _context.model.filesToLoad[_context.fileIndex];
            addCommand(new FileLoadCommand(_fileLoadContext));
            addCommand(new MethodCommand(doPrepareLoadBitmapContext, null));
            addCommand(new BitmapLoadCommand(_loadBitmapContext));
            addCommand(new MethodCommand(doPrepareReadFrameTypeContext, null));
            addCommand(new ReadFrameTypeCommand(_readFrameTypeContext));
            addCommand(new MethodCommand(doSetFrameType, null));
        }

        private function doPrepareLoadBitmapContext():Boolean
        {
            _loadBitmapContext.bytesToLoad = _fileLoadContext.fileContent;
            return true;
        }

        private function doPrepareReadFrameTypeContext():Boolean
        {
            _readFrameTypeContext.bitmapToRead = _loadBitmapContext.bitmap;
            _readFrameTypeContext.configData = _context.model.configData;
            return true;
        }

        private function doSetFrameType():Boolean
        {
            _context.model.filesToLoad[_context.fileIndex] = null;
            _context.model.frameInfos[_context.fileIndex].frameType = _readFrameTypeContext.frameType;
            return true;
        }
    }
}