package com.rokannon.project.AnimationSequenceValidator.controller.readFrameType
{
    import com.rokannon.core.command.CommandBase;
    import com.rokannon.project.AnimationSequenceValidator.model.enum.FrameType;

    public class ReadFrameTypeCommand extends CommandBase
    {
        private static const COLOR_THRESHOLD:uint = 200;

        private var _context:ReadFrameTypeContext;

        public function ReadFrameTypeCommand(context:ReadFrameTypeContext)
        {
            super();
            _context = context;
        }

        override protected function onStart():void
        {
            var color:uint = _context.bitmapToRead.bitmapData.getPixel(1, 1);
            var redColor:uint = color >> 16;
            var greenColor:uint = (color << 8) >> 16;
            if (redColor > COLOR_THRESHOLD)
                _context.frameType = FrameType.DIRECTIONAL;
            else if (greenColor > COLOR_THRESHOLD)
                _context.frameType = FrameType.STATE;
            else
                _context.frameType = FrameType.REGULAR;
            onComplete();
        }
    }
}