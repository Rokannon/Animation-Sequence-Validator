package com.rokannon.project.AnimationSequenceValidator.controller
{
    import com.rokannon.command.directoryListing.DirectoryListingCommand;
    import com.rokannon.command.directoryListing.DirectoryListingContext;
    import com.rokannon.command.fileLoad.FileLoadCommand;
    import com.rokannon.command.fileLoad.FileLoadContext;
    import com.rokannon.core.command.ConcurrentCommand;
    import com.rokannon.core.utils.string.stringFormat;
    import com.rokannon.math.utils.getMax;
    import com.rokannon.project.AnimationSequenceValidator.Main;
    import com.rokannon.project.AnimationSequenceValidator.controller.loadFrameInfo.LoadFrameInfoCommand;
    import com.rokannon.project.AnimationSequenceValidator.controller.loadFrameInfo.LoadFrameInfoContext;
    import com.rokannon.project.AnimationSequenceValidator.controller.viewStackSelect.ViewStackSelectCommand;
    import com.rokannon.project.AnimationSequenceValidator.controller.viewStackSelect.ViewStackSelectContext;
    import com.rokannon.project.AnimationSequenceValidator.model.ApplicationModel;
    import com.rokannon.project.AnimationSequenceValidator.model.FrameInfo;
    import com.rokannon.project.AnimationSequenceValidator.model.ViewStackPage;
    import com.rokannon.project.AnimationSequenceValidator.model.enum.FrameType;
    import com.rokannon.project.AnimationSequenceValidator.model.enum.Labels;

    import flash.filesystem.File;

    import mx.collections.ArrayList;
    import mx.controls.Alert;
    import mx.managers.DragManager;

    import spark.components.DataGrid;
    import spark.components.gridClasses.GridColumn;

    public class ApplicationController
    {
        private static const NUM_FILE_LOAD_THREADS:int = 30;

        private var _applicationView:com.rokannon.project.AnimationSequenceValidator.Main;
        private var _applicationModel:ApplicationModel;

        public function ApplicationController()
        {
        }

        public function connect(applicationView:com.rokannon.project.AnimationSequenceValidator.Main,
                                applicationModel:ApplicationModel):void
        {
            _applicationView = applicationView;
            _applicationModel = applicationModel;
        }

        //
        // Start Application
        //

        public function startApplication():void
        {
            var fileLoadContext:FileLoadContext = new FileLoadContext();
            fileLoadContext.fileToLoad = File.applicationDirectory.resolvePath("config.json");
            _applicationModel.commandExecutor.pushCommand(new FileLoadCommand(fileLoadContext));
            _applicationModel.commandExecutor.pushMethod(doParseConfig, true, fileLoadContext);
            _applicationModel.commandExecutor.pushMethod(handleConfigError, false);
        }

        private function doParseConfig(fileLoadContext:FileLoadContext):Boolean
        {
            try
            {
                var json:Object = JSON.parse(fileLoadContext.fileContent.toString());
                _applicationModel.configData.colorThreshold = parseInt(json["colorThreshold"]);
                _applicationModel.configData.directionalColor = _applicationModel.getColorFromString(json["directionalColor"]);
                _applicationModel.configData.stateColor = _applicationModel.getColorFromString(json["stateColor"]);
            }
            catch (error:Error)
            {
                return false;
            }
            return true;
        }

        private function handleConfigError():Boolean
        {
            Alert.show(Labels.ERROR_LOADING_CONFIG);
            return true;
        }

        //
        // Check Files to Drop
        //

        public function checkFilesToDrop(files:Vector.<File>):void
        {
            if (_applicationModel.validateFiles(files) && _applicationModel.frameInfos.length == 0)
                DragManager.acceptDragDrop(_applicationView);
        }

        //
        // Load Dropped Files
        //

        public function loadDroppedFiles(files:Vector.<File>):void
        {
            _applicationView.getViewStack().selectedIndex = ViewStackPage.LOAD_PROGRESS_BAR;

            _applicationModel.filesToLoad.length = 0;
            if (files.length == 1 && files[0].isDirectory)
            {
                var listingContext:DirectoryListingContext = new DirectoryListingContext();
                listingContext.directoryToLoad = files[0];
                _applicationModel.commandExecutor.pushCommand(new DirectoryListingCommand(listingContext));
                _applicationModel.commandExecutor.pushMethod(function ():Boolean
                {
                    for (var i:int = 0; i < listingContext.directoryListing.length; ++i)
                        _applicationModel.filesToLoad[i] = listingContext.directoryListing[i];
                    return true;
                });
            }
            else
            {
                for (var i:int = 0; i < files.length; ++i)
                    _applicationModel.filesToLoad[i] = files[i];
            }

            _applicationModel.commandExecutor.pushMethod(doSortFiles);
            _applicationModel.commandExecutor.pushMethod(doLoadFrameTypes);
            selectViewStackPage(ViewStackPage.DATA_GRID);
            _applicationModel.commandExecutor.pushMethod(doCreateDataGrid);
        }

        private function doSortFiles():Boolean
        {
            _applicationModel.filesToLoad.sort(function (file1:File, file2:File):int
            {
                if (file1.name != file2.name)
                    return file1.name > file2.name ? 1 : -1;
                return 0;
            });
            return true;
        }

        private function doLoadFrameTypes():Boolean
        {
            _applicationModel.frameInfos.length = 0;
            while (_applicationModel.frameInfos.length < _applicationModel.filesToLoad.length)
            {
                var frameInfo:FrameInfo = new FrameInfo();
                frameInfo.fileName = _applicationModel.filesToLoad[_applicationModel.frameInfos.length].name;
                frameInfo.frameType = FrameType.INVALID;
                _applicationModel.frameInfos.push(frameInfo);
            }

            var concurrentCommand:ConcurrentCommand;
            for (var i:int = 0; i < _applicationModel.filesToLoad.length; ++i)
            {
                if (i % NUM_FILE_LOAD_THREADS == 0)
                {
                    concurrentCommand = new ConcurrentCommand();
                    _applicationModel.commandExecutor.pushCommand(concurrentCommand);

                    // Suppress errors.
                    _applicationModel.commandExecutor.pushMethod(function ():Boolean
                    {
                        return true;
                    }, false);
                }
                var loadFrameTypeContext:LoadFrameInfoContext = new LoadFrameInfoContext();
                loadFrameTypeContext.fileIndex = i;
                loadFrameTypeContext.model = _applicationModel;

                var loadFrameTypeCommand:LoadFrameInfoCommand = new LoadFrameInfoCommand(loadFrameTypeContext);
                loadFrameTypeCommand.eventComplete.add(onLoadFrameTypeFinished);
                loadFrameTypeCommand.eventFailed.add(onLoadFrameTypeFinished);
                concurrentCommand.addCommand(loadFrameTypeCommand);
            }

            return true;
        }

        private function onLoadFrameTypeFinished(target:LoadFrameInfoCommand):void
        {
            ++_applicationModel.numLoadedFiles;
            target.eventComplete.remove(onLoadFrameTypeFinished);
            target.eventFailed.remove(onLoadFrameTypeFinished);
            _applicationView.getProgressBar().setProgress(_applicationModel.numLoadedFiles,
                _applicationModel.frameInfos.length);
        }

        private function doCreateDataGrid():Boolean
        {
            var info:FrameInfo;

            //
            // Number of directions.
            //

            var numDirections:int = 0;
            for each (info in _applicationModel.frameInfos)
                if (info.frameType == FrameType.DIRECTIONAL)
                    ++numDirections;

            _applicationView.getLabel1().text = stringFormat(Labels.NUM_DIRECTIONS, numDirections);
            _applicationView.getLabel1().setStyle("color", numDirections == 17 ? 0x000000 : 0xFF0000);

            var numFailed:int = 0;
            var failedName:String = null;
            for each (info in _applicationModel.frameInfos)
            {
                if (info.frameType == FrameType.INVALID)
                {
                    ++numFailed;
                    if (failedName == null)
                        failedName = info.fileName;
                }
            }

            //
            // Files failed to read.
            //

            var failedMessage:String;
            if (numFailed == 0)
                failedMessage = "-";
            else
            {
                failedMessage = failedName;
                if (numFailed > 1)
                    failedMessage += " (+" + (numFailed - 1) + ")";
            }
            _applicationView.getLabel2().text = stringFormat(Labels.FAILED_TO_READ, failedMessage);
            _applicationView.getLabel2().setStyle("color", numFailed == 0 ? 0x000000 : 0xFF0000);

            //
            // Data grid.
            //

            var sequenceReadErrors:Vector.<FrameInfo> = new <FrameInfo>[];
            var rows:Array = [];
            var currentRow:Array = null;
            var i:int;
            for (i = 0; i < _applicationModel.frameInfos.length; ++i)
            {
                info = _applicationModel.frameInfos[i];
                if (info.frameType == FrameType.DIRECTIONAL)
                {
                    if (currentRow != null)
                        rows.push(currentRow);
                    currentRow = [];
                }
                else if (info.frameType == FrameType.STATE)
                {
                    if (currentRow != null)
                        currentRow.push(0);
                    else
                        sequenceReadErrors.push(info);
                }
                else if (info.frameType == FrameType.REGULAR)
                {
                    if (currentRow != null && currentRow.length > 0)
                        ++currentRow[currentRow.length - 1];
                    else
                        sequenceReadErrors.push(info);
                }
            }
            if (currentRow != null)
                rows.push(currentRow);

            var numStates:int = 0;
            for each (currentRow in rows)
                numStates = getMax(numStates, currentRow.length);

            var cols:Array = [];
            for (i = 0; i < numStates; ++i)
                cols.push(new GridColumn("col" + i.toString()));

            var data:Array = [];
            for (i = 0; i < rows.length; ++i)
            {
                var obj:Object = {};
                data.push(obj);
                for (var j:int = 0; j < numStates; ++j)
                {
                    if (j < rows[i].length)
                        obj["col" + j.toString()] = rows[i][j];
                    else
                        obj["col" + j.toString()] = "-";
                }
            }

            var dataGrid:DataGrid = _applicationView.getDataGrid();
            dataGrid.columns = new ArrayList(cols);
            dataGrid.dataProvider = new ArrayList(data);

            //
            // Sequence read errors.
            //

            var seqReadMessage:String;
            if (sequenceReadErrors.length == 0)
                seqReadMessage = "-";
            else
            {
                seqReadMessage = sequenceReadErrors[0].fileName;
                if (sequenceReadErrors.length > 1)
                    seqReadMessage += " (+" + (sequenceReadErrors.length - 1) + ")";
            }
            _applicationView.getLabel3().text = stringFormat(Labels.SEQUENCE_ERROR_AT, seqReadMessage);
            _applicationView.getLabel3().setStyle("color", sequenceReadErrors.length == 0 ? 0x000000 : 0xFF0000);

            return true;
        }

        public function abortFileLoad():void
        {
            _applicationModel.commandExecutor.removeAllCommands();
            _applicationModel.commandExecutor.pushMethod(doAbortFileLoad);
        }

        private function doAbortFileLoad():Boolean
        {
            _applicationModel.filesToLoad.length = 0;
            _applicationModel.frameInfos.length = 0;
            _applicationModel.numLoadedFiles = 0;
            _applicationView.getProgressBar().setProgress(0, 1);
            _applicationView.getViewStack().selectedIndex = ViewStackPage.DRAG_AND_DROP;
            return true;
        }

        //
        // View Stack Select
        //

        public function selectViewStackPage(pageToSelect:int):void
        {
            var context:ViewStackSelectContext = new ViewStackSelectContext();
            context.pageToSelect = pageToSelect;
            context.viewStack = _applicationView.getViewStack();
            _applicationModel.commandExecutor.pushCommand(new ViewStackSelectCommand(context));
        }
    }
}