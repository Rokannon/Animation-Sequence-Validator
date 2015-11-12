package com.rokannon.project.AnimationSequenceValidator.controller.readFrameType
{
    import com.rokannon.core.command.CommandBase;
    import com.rokannon.project.AnimationSequenceValidator.model.enum.FrameType;

    import flash.geom.Vector3D;

    public class ReadFrameTypeCommand extends CommandBase
    {
        private static const helperVector1:Vector3D = new Vector3D();
        private static const helperVector2:Vector3D = new Vector3D();

        private var _context:ReadFrameTypeContext;

        public function ReadFrameTypeCommand(context:ReadFrameTypeContext)
        {
            super();
            _context = context;
        }

        override protected function onStart():void
        {
            prepareVector(_context.bitmapToRead.bitmapData.getPixel(1, 1), helperVector1);
            if (Vector3D.distance(helperVector1, prepareVector(_context.configData.directionalColor,
                    helperVector2)) < _context.configData.colorThreshold)
                _context.frameType = FrameType.DIRECTIONAL;
            else if (Vector3D.distance(helperVector1,
                    prepareVector(_context.configData.stateColor, helperVector2)) < _context.configData.colorThreshold)
                _context.frameType = FrameType.STATE;
            else
                _context.frameType = FrameType.REGULAR;
            onComplete();
        }

        private static function prepareVector(color:uint, resultVector:Vector3D = null):Vector3D
        {
            resultVector ||= new Vector3D();
            resultVector.setTo(color >> 16, (color << 8) >> 16, (color << 16) >> 16);
            return resultVector;
        }
    }
}