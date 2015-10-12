package com.rokannon.project.AnimationSequenceValidator.controller.viewStackSelect
{
    import com.rokannon.core.command.CommandBase;

    import mx.events.IndexChangedEvent;

    public class ViewStackSelectCommand extends CommandBase
    {
        private var _context:ViewStackSelectContext;

        public function ViewStackSelectCommand(context:ViewStackSelectContext)
        {
            super();
            _context = context;
        }

        override protected function onStart():void
        {
            if (_context.viewStack.selectedIndex == _context.pageToSelect)
            {
                onComplete();
                return;
            }
            _context.viewStack.addEventListener(IndexChangedEvent.CHANGE, onIndexChange);
            _context.viewStack.selectedIndex = _context.pageToSelect;
        }

        private function onIndexChange(event:IndexChangedEvent):void
        {
            _context.viewStack.removeEventListener(IndexChangedEvent.CHANGE, onIndexChange);
            onComplete();
        }
    }
}