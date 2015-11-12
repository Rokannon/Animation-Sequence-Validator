package com.rokannon.project.AnimationSequenceValidator
{
    import com.rokannon.project.AnimationSequenceValidator.controller.ApplicationController;
    import com.rokannon.project.AnimationSequenceValidator.model.ApplicationModel;

    import flash.desktop.ClipboardFormats;
    import flash.display.DisplayObject;
    import flash.events.NativeDragEvent;
    import flash.filesystem.File;

    import mx.containers.ViewStack;
    import mx.controls.Label;
    import mx.controls.ProgressBar;
    import mx.core.Container;
    import mx.core.UIComponent;
    import mx.core.WindowedApplication;

    import spark.components.DataGrid;

    public class Main extends WindowedApplication
    {
        private static const helperFiles:Vector.<File> = new <File>[];

        public const model:ApplicationModel = new ApplicationModel();
        public const controller:ApplicationController = new ApplicationController();

        public function Main()
        {
            super();

            addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onNativeDragEnter);
            addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onNativeDragDrop);

            controller.connect(this, model);
        }

        public function getViewStack():ViewStack
        {
            return getElementById("vs") as ViewStack;
        }

        public function getProgressBar():ProgressBar
        {
            return getElementById("pb") as ProgressBar;
        }

        public function getLabel1():Label
        {
            return getElementById("l1") as Label;
        }

        public function getLabel2():Label
        {
            return getElementById("l2") as Label;
        }

        public function getLabel3():Label
        {
            return getElementById("l3") as Label;
        }

        public function getDataGrid():DataGrid
        {
            return getElementById("dg") as DataGrid;
        }

        private function getElementById(id:String, parentElement:UIComponent = null):UIComponent
        {
            parentElement ||= this;
            if (parentElement.id == id)
                return parentElement;
            if (parentElement is Container)
            {
                var container:Container = parentElement as Container;
                for (var i:int = 0; i < container.numChildren; ++i)
                {
                    var child:DisplayObject = container.getChildAt(i);
                    if (child is UIComponent)
                    {
                        var childElement:UIComponent = child as UIComponent;
                        var resultElement:UIComponent = getElementById(id, childElement);
                        if (resultElement != null)
                            return resultElement;
                    }
                }
            }
            return null;
        }

        private function onNativeDragEnter(event:NativeDragEvent):void
        {
            if (!event.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
                return;
            var files:Array = event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
            prepareHelperFiles(files);
            controller.checkFilesToDrop(helperFiles);
            helperFiles.length = 0;

        }

        private function onNativeDragDrop(event:NativeDragEvent):void
        {
            var files:Array = event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
            prepareHelperFiles(files);
            controller.loadDroppedFiles(helperFiles);
            helperFiles.length = 0;
        }

        private static function prepareHelperFiles(files:Array):void
        {
            for (var i:int = 0; i < files.length; ++i)
                helperFiles[i] = files[i];
        }
    }
}