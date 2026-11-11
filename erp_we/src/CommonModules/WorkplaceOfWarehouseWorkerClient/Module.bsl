////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions that are called from the processing forms
// of the "Workbench".
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Handler for the pre-Closing event.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
// 	Cancel - Boolean - The truth is, if you do not want to close the form the workplace.
// 	WarningText - String - warning displayed to the user before closing the form.
// 	StandardProcessing - Boolean - The truth is, if you are a standard, systematic treatment of the form is closed.
//
Procedure BeforeClose(Form, Cancel, WarningText, StandardProcessing) Export
	
	Items = Form.Items;
	GoodsForScanning = Form.GoodsForScanning;
	YouCanCloseForm = Form.ModeSettings.YouCanCloseForm;
	CurrentPage = Form.Items.FormPages.CurrentPage;
	
	If Not YouCanCloseForm Then
		
		Cancel = True;
		StandardProcessing = False;
		
		If CurrentPage = Items.ScanPage
			Or CurrentPage = Items.EnterQuantityPage
			Or CurrentPage = Items.SelectDestinationPage
			Or CurrentPage = Items.SelectAShippingAcceptanceZonePage
			Or GoodsForScanning.Count() > 0 Then
			
			WarningText = NStr("vi = 'Chưa kết thúc thực hiện nhiệm vụ kho.
				|Sẽ ngắt chỗ làm việc di động của nhân viên kho.';
				|ru = 'Выполнение складского задания не завершено.
				|Работа мобильного рабочего места работника склада будет прервана.';
				|en = 'Warehouse task is not completed.
				|Mobile workplace of the warehouse worker will be closed.'; fa = 'Warehouse task is not completed.
				|Mobile workplace of the warehouse worker will be closed.';
				|it = 'Task di magazzino non è stato completato.
				| Il lavoro della postazione mobile del dipendente del magazzino sarà interrotto.';
				|pl = 'Wykonanie zadania magazynowego nie ukończono.
				|Działanie mobilnego miejsca pracy pracownika magazynu zostanie przerwane.';
				|tr = 'Ambar görevi tamamlanmadı.
				|Ambar çalışanının mobil çalışma alanı kesintiye uğrayacak.'");
			
		Else
			WarningText = NStr("vi = 'Công việc tại nơi làm việc di động của nhân viên kho sẽ bị gián đoạn.';
								|ru = 'Работа мобильного рабочего места работника склада будет прервана.';
								|en = 'Mobile workplace of the warehouse worker will be closed.'; fa = 'Mobile workplace of the warehouse worker will be closed.';
								|it = 'Il lavoro della postazione mobile del dipendente del magazzino sarà interrotto.';
								|pl = 'Działanie mobilnego miejsca pracy pracownika magazynu zostanie przerwane.';
								|tr = 'Ambar çalışanının mobil çalışma alanı çalışması kesintiye uğrayacaktır.'");
		EndIf;
		
	EndIf;
	
EndProcedure

// Handler for the Closing event.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure OnClose(Form) Export
	
	// ExternalEquipmentMechanism
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, Form);
	// End ExternalEquipmentMechanism
	
	If Not Form.IsFullUser Then
		Exit(False);
	EndIf;
	
EndProcedure

// Called when entering a quantity on a page intended for manually specifying the number of scanned products.
// Recalculates the values in the fields intended for manually specifying the weight and volume of scanned products.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure EnterTheNumberOfTheNumberOnChange(Form) Export
	
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If Not (CurrentScanningLine.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
		And (CurrentScanningLine.PackageWeight <> 0) Then
		
		Form.EnterQuantityWeight = Form.EnterTheNumberOfTheNumber * CurrentScanningLine.PackageWeight
			/ CurrentScanningLine.FactorOfWeightUnitOfMeasure;
		
	EndIf;
	
	If Not (CurrentScanningLine.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
		And (CurrentScanningLine.PackageVolume <> 0) Then
		
		Form.EnterQuantityVolume = Form.EnterTheNumberOfTheNumber * CurrentScanningLine.PackageVolume
			/ CurrentScanningLine.FactorOfVolumeUnitOfMeasure;
		
	EndIf;
	
EndProcedure

// Called when entering a quantity on a page intended for manually specifying the weight of scanned items.
// Recalculates the values in the fields intended for manually specifying the quantity and volume of scanned 
// products.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure EnterQuantityWeightOnChange(Form) Export
	
	JobType = Form.ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	Form.EnterTheNumberOfTheNumber = Form.EnterQuantityWeight * CurrentScanningLine.FactorOfWeightUnitOfMeasure
		/ CurrentScanningLine.PackageWeight;
	
	RoundUpNumberOfPackages(JobType, CurrentScanningLine, Form.EnterTheNumberOfTheNumber);
	
	If Not (CurrentScanningLine.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
		And (CurrentScanningLine.PackageVolume <> 0) Then
		
		Form.EnterQuantityVolume = Form.EnterTheNumberOfTheNumber * CurrentScanningLine.PackageVolume
			/ CurrentScanningLine.FactorOfVolumeUnitOfMeasure;
		
	EndIf;
	
EndProcedure

// Called when entering a quantity on a page intended for manually specifying the volume of scanned products.
// Recalculates the values in the fields intended for manually specifying the quantity and weight of scanned 
// products.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure EnterQuantityVolumeOnChange(Form) Export
	
	JobType = Form.ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	Form.EnterTheNumberOfTheNumber = Form.EnterQuantityVolume
		* CurrentScanningLine.FactorOfVolumeUnitOfMeasure / CurrentScanningLine.PackageVolume;
	
	RoundUpNumberOfPackages(JobType, CurrentScanningLine, Form.EnterTheNumberOfTheNumber);
	
	If Not (CurrentScanningLine.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
		And (CurrentScanningLine.PackageWeight <> 0) Then
		
		Form.EnterQuantityWeight = Form.EnterTheNumberOfTheNumber * CurrentScanningLine.PackageWeight
			/ CurrentScanningLine.FactorOfWeightUnitOfMeasure;
		
	EndIf;
	
EndProcedure

// Called when the "OK" command is selected on the page intended for manually specifying the quantity of the scanned 
// product.
// Connects procedures to be used as handlers ' expectations, after clicking "OK".
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure EnteringTheQuantityOK(Form) Export
	
	CurMessageToUser = "";
	
	If Form.ModeSettings.ProcessingProcedure_ = PredefinedValue("Enum.WarehouseJobProcessingProcedure.StorageBinGoods") Then
		If Form.CurrentScanningLine.NumberOfPackagingsScanned = Form.EnterTheNumberOfTheNumber Then
			If Form.CurrentScanningLine.NewAssignment = Form.CurrentScanningLine.Purpose Then
				Form.EnteringQuantityIsCanceled = True;
			EndIf;
		EndIf;
	Else
		If Form.CurrentScanningLine.NumberOfPackagesToPut = Form.EnterTheNumberOfTheNumber Then
			Form.EnteringQuantityIsCanceled = True;
		EndIf;
	EndIf;
	
	Form.AttachIdleHandler("Attachable_EnteringNumberOfOKWaitHandler", 0.5, True);
	Form.AttachIdleHandler("Attachable_DisplaysStateOfJobExecutionWaitingHandler", 5, True);
	
EndProcedure

// Called when you select the "Cell" command on the page that is intended for scanning items 
// in the warehouse task.
// Clears the "text message to User" form field.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ScanCell(Form) Export
	
	MessageToUserText = "";
	
EndProcedure

// Executes closing the form the mobile workplace of the storekeeper.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CloseTheFormOfMobileWorkplace(Form) Export
	
	Form.ModeSettings.YouCanCloseForm = True;
	Form.Close();
	
EndProcedure

// Called when the " OK " command is selected on pages intended for manually specifying the cell address, 
// product barcode, or serial number.
// Clears the "text message to User" form field.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SelectingTheOKValue(Form) Export
	
	CurMessageToUser = "";
	
EndProcedure

// Called when the barcode value is changed on a page intended for manually specifying the cell address, 
// product barcode, or serial number.
// Connects procedures that are used as wait handlers.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure BarcodeOfTheScanParameterOnChange(Form) Export
	
	Form.SeriesShelfLife = "";
	
	If Not Form.Items.SeriesShelfLife.Visible Then
		Form.AttachIdleHandler("Attachable_SelectingOKValueWaitHandler", 0.5, True);
		Form.AttachIdleHandler("Attachable_DisplaysStateOfJobExecutionWaitingHandler", 5, True);
	EndIf;
	
EndProcedure

// Called when the value of the cell address changes on the page intended for manually specifying the address of the problem 
// cell.
// Connects procedures that are used as wait handlers.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure StorageBinLocationOnChange(Form) Export
	
	Form.AttachIdleHandler("Attachable_AddressSelectionOKWaitHandler", 0.5, True);
	
EndProcedure

// Called when the expiration date of a series is changed on a page intended for manually specifying the expiration 
// date of a product series.
// Connects procedures that are used as wait handlers.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SeriesShelfLifeOnChange(Form) Export
	
	Form.AttachIdleHandler("Attachable_SelectingOKValueWaitHandler", 0.5, True);
	Form.AttachIdleHandler("Attachable_DisplaysStateOfJobExecutionWaitingHandler", 5, True);
	
EndProcedure

// Updates the list of warehouse tasks on the page intended for selecting the task.
//
// Parameters:
// 	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** Jobs - FormTable - a table containing information about warehouse tasks.
//
Procedure TasksUpdate(Form) Export
	
	Form.Items.Jobs.Refresh();
	
EndProcedure

// Determines whether the list of warehouse tasks needs to be updated.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//  Boolean - True, a sign that you need to update the list of warehouse tasks.
//
Function NeedToUpdateTaskList(Form) Export
	
	Return Form.Items.FormPages.CurrentPage = Form.Items.OperationSelectionPage
		Or Form.Items.FormPages.CurrentPage = Form.Items.PageJobSelection;
	
EndFunction

// Determines whether the status of the warehouse task execution status needs to be updated.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//  Boolean - True, a sign that the status of the warehouse task completion status needs to be updated.
//
Function YouNeedToUpdateTaskState(Form) Export
	
	Return Form.Items.FormPages.CurrentPage = Form.Items.ScanPage;
	
EndFunction

#EndRegion

#Region Private

// Rounds the specified number of packages to an integer value.
//
// Parameters:
//	JobType 					- String 				- type of warehouse task.
//	CurrentScanningLine 	- FormDataStructure 	- structure with a description of the processed product.
//	NumberOfPackages 			- Number 				- the number of packs of the product prior to rounding.
//
Procedure RoundUpNumberOfPackages(JobType, CurrentScanningLine, NumberOfPackages)
	
	If JobType = "Receiving"
		Or JobType = "Recalculate" Then
		
		Return;
		
	EndIf;
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	
	If ValueIsFilled(CurrentScanningLine.Package)
		Or (Not ValueIsFilled(CurrentScanningLine.Package)
			And DimensionalUnitsOfMeasurement.Find(CurrentScanningLine.MeasuredValueType) = Undefined) Then
		
		NumberOfPackages = Round(NumberOfPackages);
		
	EndIf;
	
EndProcedure

// Returns an array whose elements are values of dimensional types of measured values.
//
// Returns:
//	Array - the elements are the values of the dimensional types of the measured quantities.
//
Function DimensionalUnitsOfMeasurement()
	
	DimensionalUnitsOfMeasurement = New Array;
	DimensionalUnitsOfMeasurement.Add(PredefinedValue("Enum.TypesOfMeasuredValues.Weight"));
	DimensionalUnitsOfMeasurement.Add(PredefinedValue("Enum.TypesOfMeasuredValues.VolumeM3"));
	DimensionalUnitsOfMeasurement.Add(PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
	DimensionalUnitsOfMeasurement.Add(PredefinedValue("Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement"));
	
	Return DimensionalUnitsOfMeasurement;
	
EndFunction

#EndRegion
