////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions that are called from the processing forms
// of the "Workbench". Separate forms have been created for different screen resolutions
// . All calls are passed from forms to this common module.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Sets the values of form details that are necessary to take into account how
// forms are displayed on devices with different screen extensions.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetSettingsForScreenResolution(Form) Export
	
	If Form.ScreenResolution = Enums.ScreenResolutions.Resolution240x320 Then
		Form.TextTitleFormLength = 25;
		Form.FormTitleTextLengthForComparison = 21;
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution320x320 Then
		Form.TextTitleFormLength = 34;
		Form.FormTitleTextLengthForComparison = 29;
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
		Form.TextTitleFormLength = 54;
		Form.FormTitleTextLengthForComparison = 44;
	EndIf;
	
EndProcedure

// Returns an array of users who perform warehouse tasks.
// An empty link is included in the user array.
//
// Parameters:
//	User - CatalogRef.Users - performer of the warehouse task.
//
// Returns:
//	FixedArray of CatalogRef.Users - all performers of warehouse tasks.
//
Function AllWarehouseTaskPerformers(User) Export
	
	TaskPerformers_ = New Array;
	TaskPerformers_.Add(User);
	TaskPerformers_.Add(Catalogs.Users.EmptyRef());
	
	Return New FixedArray(TaskPerformers_);
	
EndFunction

// Returns an array of users who perform warehouse tasks.
//
// Parameters:
//	User - CatalogRef.Users - the current contractor.
//
// Returns:
//	FixedArray of CatalogRef.Users - performers of warehouse tasks.
//
Function WarehouseTaskPerformers(User) Export
	
	TaskPerformers_ = New Array;
	TaskPerformers_.Add(User);
	
	Return New FixedArray(TaskPerformers_);
	
EndFunction

// The procedure updates the headers of the main menu items for selecting the operation type.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure UpdateMainMenu(Form) Export
	
	If Form.WebServiceMode Then
		
		ServiceVersion = WorkplaceOfWarehouseWorkerXDTO.ServiceVersionFromForm(Form);
		Proxy = WorkplaceOfWarehouseWorkerXDTO.ProxyWebService(
			Form.UserName, Form.Password, Form.WSDLLocation, ServiceVersion);
		
		// Receiving
		JobsCount = WorkplaceOfWarehouseWorkerXDTO.NumberOfWarehouseTasks(Form, Proxy, "Receiving");
		SetPropertiesOfMainMenuItem(Form, "MainMenuAcceptance", NStr("vi = 'Nhập kho';
																	|ru = 'Приемка';
																	|en = 'Inventory receipt'; fa = 'Inventory receipt';
																	|it = 'Accettazione';
																	|pl = 'Przyjęcie';
																	|tr = 'Kabul'"), JobsCount);
		
		// Location
		JobsCount = WorkplaceOfWarehouseWorkerXDTO.NumberOfWarehouseTasks(Form, Proxy, "Location");
		SetPropertiesOfMainMenuItem(Form, "MainMenuPlacement", NStr("vi = 'Xếp vào';
																	|ru = 'Размещение';
																	|en = 'Inventory put-away'; fa = 'جای‌گذاری موجودی';
																	|it = 'Collocamento';
																	|pl = 'Lokalizacja';
																	|tr = 'Yerleşim'"), JobsCount);
		
		// Filter
		JobsCount = WorkplaceOfWarehouseWorkerXDTO.NumberOfWarehouseTasks(Form, Proxy, "Filter");
		SetPropertiesOfMainMenuItem(Form, "MainMenuSelection", NStr("vi = 'Lọc';
																	|ru = 'Отбор';
																	|en = 'Inventory picking'; fa = 'Inventory picking';
																	|it = 'Selezione';
																	|pl = 'Inventory picking';
																	|tr = 'Filtre'"), JobsCount);
		
		// Checking the selection
		JobsCount = WorkplaceOfWarehouseWorkerXDTO.NumberOfWarehouseTasks(Form, Proxy, "PickingCheck");
		SetPropertiesOfMainMenuItem(Form, "MainMenuSelectionCheck", NStr("vi = 'Kiểm tra sàng lọc';
																		|ru = 'Проверка отбора';
																		|en = 'Follow-up check'; fa = 'بررسی پیگیری';
																		|it = 'Verifica selezione';
																		|pl = 'Weryfikacja filtru';
																		|tr = 'Filtre kontrolü'"),
			JobsCount);
		
		// Recalculate
		JobsCount = WorkplaceOfWarehouseWorkerXDTO.NumberOfWarehouseTasks(Form, Proxy, "Recalculate");
		SetPropertiesOfMainMenuItem(Form, "MainMenuRecalculate", NStr("vi = 'Tính lại';
																		|ru = 'Пересчет';
																		|en = 'Inventory count'; fa = 'شمارش موجودی';
																		|it = 'Ricalcolo';
																		|pl = 'Inventory count';
																		|tr = 'Yeniden hesaplama'"), JobsCount);
		
		// Move
		JobsCount = WorkplaceOfWarehouseWorkerXDTO.NumberOfWarehouseTasks(Form, Proxy, "Move");
		SetPropertiesOfMainMenuItem(Form, "MainMenuMove", NStr("vi = 'Điều chuyển';
																|ru = 'Перемещение';
																|en = 'Inventory transfer'; fa = 'انتقال موجودی';
																|it = 'Spostamento';
																|pl = 'Inventory transfer';
																|tr = 'Transfer'"),
			JobsCount);
		
	Else
		
		AllAssignees = AllWarehouseTaskPerformers(Form.User);
		
		// Receiving
		JobsCount = WorkplaceOfWarehouseWorkerApplicationInterface.NumberOfWarehouseTasksToComplete(
			Form.Warehouse, Form.Premise, "Receiving", AllAssignees);
		SetPropertiesOfMainMenuItem(Form, "MainMenuAcceptance", NStr("vi = 'Nhập kho';
																	|ru = 'Приемка';
																	|en = 'Inventory receipt'; fa = 'Inventory receipt';
																	|it = 'Accettazione';
																	|pl = 'Przyjęcie';
																	|tr = 'Kabul'"), JobsCount);
		
		// Location
		JobsCount = WorkplaceOfWarehouseWorkerApplicationInterface.NumberOfWarehouseTasksToComplete(
			Form.Warehouse, Form.Premise, "Location", AllAssignees);
		SetPropertiesOfMainMenuItem(Form, "MainMenuPlacement", NStr("vi = 'Xếp vào';
																	|ru = 'Размещение';
																	|en = 'Inventory put-away'; fa = 'جای‌گذاری موجودی';
																	|it = 'Collocamento';
																	|pl = 'Lokalizacja';
																	|tr = 'Yerleşim'"),
			JobsCount);
		
		// Filter
		JobsCount = WorkplaceOfWarehouseWorkerApplicationInterface.NumberOfWarehouseTasksToComplete(
			Form.Warehouse, Form.Premise, "Filter", AllAssignees);
		SetPropertiesOfMainMenuItem(Form, "MainMenuSelection", NStr("vi = 'Lọc';
																	|ru = 'Отбор';
																	|en = 'Inventory picking'; fa = 'Inventory picking';
																	|it = 'Selezione';
																	|pl = 'Inventory picking';
																	|tr = 'Filtre'"), JobsCount);
		
		// Checking the selection
		JobsCount = WorkplaceOfWarehouseWorkerApplicationInterface.NumberOfWarehouseTasksToComplete(
			Form.Warehouse, Form.Premise, "PickingCheck", AllAssignees);
		SetPropertiesOfMainMenuItem(Form, "MainMenuSelectionCheck", NStr("vi = 'Kiểm tra sàng lọc';
																		|ru = 'Проверка отбора';
																		|en = 'Follow-up check'; fa = 'بررسی پیگیری';
																		|it = 'Verifica selezione';
																		|pl = 'Weryfikacja filtru';
																		|tr = 'Filtre kontrolü'"),
			JobsCount);
		
		// Recalculate
		JobsCount = WorkplaceOfWarehouseWorkerApplicationInterface.NumberOfWarehouseTasksToComplete(
			Form.Warehouse, Form.Premise, "Recalculate", AllAssignees);
		SetPropertiesOfMainMenuItem(Form, "MainMenuRecalculate", NStr("vi = 'Tính lại';
																		|ru = 'Пересчет';
																		|en = 'Inventory count'; fa = 'شمارش موجودی';
																		|it = 'Ricalcolo';
																		|pl = 'Inventory count';
																		|tr = 'Yeniden hesaplama'"), JobsCount);
		
		// Move
		JobsCount= WorkplaceOfWarehouseWorkerApplicationInterface.NumberOfWarehouseTasksToComplete(
			Form.Warehouse, Form.Premise, "Move", AllAssignees);
		SetPropertiesOfMainMenuItem(Form, "MainMenuMove", NStr("vi = 'Điều chuyển';
																|ru = 'Перемещение';
																|en = 'Inventory transfer'; fa = 'انتقال موجودی';
																|it = 'Spostamento';
																|pl = 'Inventory transfer';
																|tr = 'Transfer'"),
			JobsCount);
	EndIf;
	
EndProcedure

// The procedure displays all available (or only available to the current performer)
// warehouse tasks in the list of tasks.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure DisplayAllYourWarehouseJobsOnly(Form) Export
	
	Jobs = Form.Jobs;
	Form.DisplayAllJobs = Not (Form.DisplayAllJobs);
	
	If Form.DisplayAllJobs Then
		Form.Items.Jobs.RowFilter = Undefined;
		DocumentsCount = Jobs.Count();
	Else
		Filter = New Structure("Performer", Form.User);
		DocumentsCount = Jobs.FindRows(Filter).Count();
		
		Form.Items.Jobs.RowFilter = New FixedStructure(Filter);
	EndIf;
	
	SetTaskListTitle(Form, DocumentsCount);
	
EndProcedure

// Switches the form page panel to the task selection page. Sets parameters for the dynamic
// list of tasks.
//
// Parameters:
// Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 	* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 		** Jobs - FormTable - a table containing information about warehouse tasks.
// 		** TasksShowAll - FormButton - a button that filters the display of all warehouse tasks.
// JobType - String - type of warehouse task.
//
Procedure GoToTaskSelection(Form, JobType) Export
	
	Jobs = Form.Jobs;
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	WebServiceMode = Form.WebServiceMode;
	
	// Set the parameters of the current mode.
	ModeSettings.Mode = "SelectJob";
	ModeSettings.JobType = JobType;
	
	// Set the title text of the form - the type of tasks and their number.
	AllAssignees = AllWarehouseTaskPerformers(Form.User);
	
	// Set the task list parameters.
	Jobs.Clear();
	
	If WebServiceMode Then
		TaskTable = WorkplaceOfWarehouseWorkerXDTO.TaskTable(Form, JobType);
	Else
		TaskTable = WorkplaceOfWarehouseWorkerApplicationInterface.TaskTable(Form.Warehouse, Form.Premise,
			JobType, AllAssignees);
	EndIf;
	
	If Form.DisplayAllJobs Then
		DocumentsCount = TaskTable.Count();
		
		Form.Items.Jobs.RowFilter = Undefined;
	Else
		Filter = New Structure("Performer", Form.User);
		DocumentsCount = TaskTable.FindRows(Filter).Count();
		
		Form.Items.Jobs.RowFilter = New FixedStructure(Filter);
	EndIf;
	
	// Set the title text of the form - the type of tasks and their number.
	SetTaskListTitle(Form, DocumentsCount);
	
	Jobs.Load(TaskTable);
	
	// Set the parameters of the task list columns.
	Items.Jobs.Refresh();
	
	// Reset the visibility of auxiliary columns
	Items.JobsWeight.Visible = False;
	Items.JobsDeliveryProcedure.Visible = False;
	Items.TasksUnitOfMeasurement.Visible = False;
	
	If JobType = "Filter"
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		Items.JobsWeight.Visible = True;
		Items.TasksUnitOfMeasurement.Visible = True;
		
	ElsIf JobType = "PickingCheck"
		And Form.DeliveryManagementIsUsed Then
		
		Items.JobsDeliveryProcedure.Visible = True;
		
	EndIf;
	
	// The acceptance must always have a responsible person specified, there cannot be an empty executor.
	Items.TasksShowAll.Enabled = Not (JobType = "Receiving");
	
	GoToPage3(Form, "PageJobSelection");
	
EndProcedure

// Called when entering a quantity on a page intended for manually specifying the number of scanned products.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure EnterQuantity(Form) Export
	
	ResetSignsOfScanningAllParameters(Form);
	SetParameterScanFlag(Form, "Count", True);
	GoToNextScanOption(Form);
	WhenScanningValue(Form, Form.EnterTheNumberOfTheNumber);
	
EndProcedure

// Performed when scanning the task barcode when the task list form is active.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Barcode - String - barcode of the warehouse task document.
//
Procedure WhenScanningTaskBarcode(Form, Barcode) Export
	
	If Not ValueIsFilled(Barcode) Then
		Return;
	EndIf;
	
	WebServiceMode = Form.WebServiceMode;
	OperationSelectionMode = (Form.ModeSettings.Mode = "OperationSelection");
	
	JobType = Form.ModeSettings.JobType;
	
	If WebServiceMode Then
		JobParameters = WorkplaceOfWarehouseWorkerXDTO.BarcodeTaskParameters(Form, Barcode, JobType);
	Else
		JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.BarcodeTaskParameters(Barcode, Form.Warehouse,
			Form.Premise, Form.User, JobType, OperationSelectionMode);
	EndIf;
	
	If JobParameters.ReturnCode = 0 Then
		
		If OperationSelectionMode Then
			JobType = "";
		EndIf;
		
		Buttons = New ValueList;
		AddButtonToGoToTaskSelection(Buttons, JobType);
		
		ShowMessageDialog(Form, JobParameters.MessageText, Buttons);
		
		Return;
		
	EndIf;
	
	TakeTaskToWork(Form, JobParameters.Job, JobParameters);
	
EndProcedure

// It is performed when scanning the barcode value of a product or series,
// or when entering the value using the manual input mode.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ScanValue - String, Number - the value of the scan.
//	AdditionalScanValue - Undefined - additional parameter, used if
//		the scan value was entered manually.
//	ThisIsScan - Boolean - True if the scan value was received via the TSD.
//
Procedure WhenScanningValue(Form, Val ScanValue, AdditionalScanValue = Undefined,
	ThisIsScan = False) Export
	
	Var Cell, OwnGoods, Series;
	
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	ScanParameter = Form.ModeSettings.ScanParameter;
	
	If (JobType = "Recalculate"
			Or (JobType = "Location"
				And ThisIsSetOfGoods)
			Or JobType = "Receiving"
			Or JobType = "PickingCheck")
		And ScanParameter = "Series"
		And (ThisIsProductBarcode(ScanValue, OwnGoods)
			Or (JobType = "Receiving"
				And Not ThisIsBarcodeOfSeries(Form, ScanValue, AdditionalScanValue)
				And ThisIsBarcodeOfPackingList(ScanValue, AdditionalScanValue, OwnGoods))) Then
		
		If Not ItemMatchesScanLineItem(Form.CurrentScanningLine, OwnGoods) Then
			Form.ModeSettings.ScanParameter = "Products";
			ScanParameter = "Products";
		EndIf;
	EndIf;
	
	HasErrors = False;
	
	If ScanParameter = "Cell" Then
		WhenScanningCell(Form, ScanValue, Cell, HasErrors, ThisIsScan);
		AfterScanningCell(Form, Cell, HasErrors);
	ElsIf ScanParameter = "Products" Then
		WhenScanningItem(Form, ScanValue, OwnGoods, HasErrors);
		AfterScanningProduct(Form, OwnGoods, HasErrors);
		
		If Form.ModeSettings.Mode = "EnterQuantity" Then
			Return;
		EndIf;
	ElsIf ScanParameter = "Series" Then
		WhenScanningSeries(Form, ScanValue, AdditionalScanValue, Series, HasErrors);
		AfterScanningSeries(Form, Series, HasErrors);
		
		If Form.ModeSettings.Mode = "EnterQuantity" Then
			Return;
		EndIf;
	ElsIf ScanParameter = "Count" Then
		ScanValue = WhenEnteringQuantity(Form, ScanValue, HasErrors);
		If Form.ModeSettings.Mode = "EnteringQuantityAsIntended" Then
			AfterEnteringQuantity(Form, Max(0, Form.CurrentScanningLine.NumberOfPackagingsScanned - ScanValue), HasErrors);
			Form.CurrentScanningLine.Purpose = Form.CurrentScanningLine.NewAssignment;
		EndIf;
		AfterEnteringQuantity(Form, ScanValue, HasErrors);
	EndIf;
	
	// Clear the values of the elements on the value selection page.
	Form.BarcodeOfTheScanParameter = "";
	Form.SeriesShelfLife = "";
	
	Form.EnterQuantityWeight = 0;
	Form.EnterQuantityVolume = 0;
	Form.EnterTheNumberOfTheNumber = 0;
	
	Form.ErrorMessage = "";
	
	If HasErrors Then
		HandleErrorWhenScanningValue(Form, ScanValue, OwnGoods);
	Else
		AfterScanningValue(Form);
		DisplayTaskState(Form);
		SetParametersForScanItems(Form);
		SetHotkeysOnCurPage(Form);
		HandleWarningWhenScanningValue(Form);
	EndIf;
	
	Form.ModeSettings.Mode = "Scanning";
	
EndProcedure

// Executed when the product scan of the current task is completed.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure WhenCurJobScanIsComplete(Form) Export
	
	ModeSettings = Form.ModeSettings;
	JobType = Form.ModeSettings.JobType;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	
	ThereAreScannedProducts = ThereAreScannedProducts(Form);
	
	If JobType = "Filter" 
		Or JobType = "Location" 
		Or JobType = "Recalculate" Then
		
		FinishJobExecution(Form);
		
	ElsIf JobType = "Move" Then
		
		If Not SelectionScanned Then
			
			If ThereAreScannedProducts Then
				
				If Not AllJobLinesAreScanned(Form) Then
					AddContainerForScannedProduct(Form);
				EndIf;
				
				ProcessScannedGoodsForMoving(Form);
				
				GoodsParameters = TaskProductParameters(Form);
				FillPropertyValues(ModeSettings, GoodsParameters);
				
				Form.CurrentScanningLine = Undefined;
				Form.ErrorMessage = "";
				
				FillInDataForScanningJob(Form);
				
				If Not ModeSettings.GoodsAreDistributed Then
					
					Form.ModeSettings.GoodsAreDistributed = True;
					
					WarningText = NStr("vi = 'Không thể xếp vào số lượng hàng hóa đã chọn với nhiệm vụ kho.
					|Sẽ kết thúc thực hiện nhiệm vụ xếp vào.
					|Cần chuyển hàng hóa đã chọn 
					|vào khu vực nhập hàng.';
					|ru = 'Отобранное количество товаров невозможно разместить в соответствии со складским заданием.
					|Выполнение задания на перемещение будет завершено.
					|Отобранные товары следует отнести 
					|в зону приемки.';
					|en = 'The quantity of picked items deviates from the quantity in the Put-away list.
					|The transfer task will be canceled.
					|Please deliver the picked items 
					|to the inbound area.'; fa = 'The quantity of picked items deviates from the quantity in the Put-away list.
					|The transfer task will be canceled.
					|Please deliver the picked items 
					|to the inbound area.';
					|it = 'Non è possibile collocare in corrispondenza con il task di magazzino la quantità selezionata di merci. 
					| L''esecuzione del task per lo spostamento sarà terminato. 
					|Le merci selezionate devono essere portate 
					|nell''area di accettazione.';
					|pl = 'Wybraną ilość towarów nie można rozmieścić zgodnie z zadaniem magazynowym.
					|Wykonanie zadania na przemieszczenie zostanie zakończone.
					|Wybrane wiersze pozycji należy zanieść 
					|do strefy odbioru.';
					|tr = 'Ambar görevine göre seçilen ürün miktarı yerleştirilemez.
					|Transfer işi tamamlanacaktır.
					|Seçilen ürünler boşaltma alanına 
					|taşınmalıdır.'");
					
					GoToAcceptanceZoneSelectionButton = NewDialogButton("GoToSelectionOfAReceivingArea",
						NStr("vi = 'Đồng ý';
							|ru = 'ОК';
							|en = 'OK'; fa = 'تأیید';
							|it = 'OK';
							|pl = 'OK';
							|tr = 'Tamam'"),
						True);
					ShowMessageDialog(Form, WarningText, GoToAcceptanceZoneSelectionButton);
					
					Return;
					
				EndIf;
				
				FillInRemainingItemsInCell(Form);
				
				Form.ScannedGoods.Clear();
				Form.ScannedPackage.GetItems().Clear();
				
				SetInitialStateOfJob(Form);
				CreateQueueOfScanParameters(Form);
				
				GoToScanning(Form);
				
			Else
				
				WarningText = NStr("vi = 'Chưa thực hiện lấy ra hàng hóa.
				|Chưa lấy ra hàng hóa nào.
				|Sẽ ngắt thực hiện nhiệm vụ điều chuyển.';
				|ru = 'Отбор товаров не выполнен.
				|Не отобрано ни одного товара.
				|Выполнение задания на перемещение будет прервано.';
				|en = 'You haven''t picked any item.
				|The transfer task will be canceled.
				|'; fa = 'You haven''t picked any item.
				|The transfer task will be canceled.
				|';
				|it = 'Selezione di merci non eseguita. 
				| Non è stata selezionata nessuna merce. 
				|Esecuzione del task per lo spostamento sarà interrotta.';
				|pl = 'Filtr towarów nie został wykonany.
				|Nie wybrano żadnego towaru.
				|Wykonanie zadania na przemieszczenie zostanie przerwane.';
				|tr = 'Ürün toplanması gerçekleştirilmedi.
				|Hiç bir ürün toplanmadı.
				|Transfer işi iptal edilecek.'");
				
				ContinueScanningButton = NewDialogButton("ReturnToTheJob",
					NStr("vi = 'Tiếp tục lấy ra hàng hóa';
						|ru = 'Продолжить отбор товаров';
						|en = 'Resume picking job'; fa = 'Resume picking job';
						|it = 'Continuare la selezione dei prodotti';
						|pl = 'Kontynuuj wybór towarów';
						|tr = 'Ürünleri filtrelemeye devam et'"), True);
				AbortExecutionButton = NewDialogButton("AbortJobExecution",
					NStr("vi = 'Ngắt thực hiện nhiệm vụ';
						|ru = 'Прервать выполнение задания';
						|en = 'Abort task'; fa = 'Abort task';
						|it = 'Interrompere esecuzione task';
						|pl = 'Przerwij wykonywanie zadania';
						|tr = 'Görevin gerçekleştirilmesini durdur'"));
				
				Buttons = New ValueList;
				Buttons.Add(ContinueScanningButton);
				Buttons.Add(AbortExecutionButton);
				
				ShowMessageDialog(Form, WarningText, Buttons);
				
			EndIf;
			
		Else
			ModeSettings.PlacementScanned = True;
			FinishJobExecution(Form);
		EndIf;
		
	EndIf;
	
EndProcedure

// Called when the command to move to the next item in a form of dialogue of the workplace.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToTheNextScanningGoods(Form) Export
	
	WebServiceMode = Form.WebServiceMode;
	JobType = Form.ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
		
	If Not (JobType = "Filter"
		Or JobType = "Location")
		Or ThisIsProcessingOrderOfItemCell Then
		
		If ThisIsLastLineOfScan(Form) Then
			GoToNextScanLine(Form);
		Else
			GoToNextScanLine(Form);
			SetParametersForScanItems(Form);
			GoToPage3(Form,"ScanPage");
			DisplayTaskState(Form);
		EndIf;
		
	Else
		
		Parameter_1 = "";
		Parameter_2 = "";
		
		MessageText = NStr("vi = 'Không phải tất cả hàng hóa là %1 ""%2"" cho nhiệm vụ hiện tại. %3';
							|ru = 'Не все товары были %1 ""%2"" по текущему заданию. %3';
							|en = 'Not all items have been processed. %1 %2. %3'; fa = 'Not all items have been processed. %1 %2. %3';
							|it = 'Non tutti i prodotti erano %1 ""%2"" secondo il task corrente. %3';
							|pl = 'Nie wszystkie wiersze pozycji zostały %1 ""%2"" dla aktualnego zadania. %3';
							|tr = 'Tüm ürünler %1 ""%2"" mevcut görev için değildir. %3'");
		If JobType = "Filter" Then
			Parameter_1 = NStr("vi = 'được chọn từ ô';
								|ru = 'отобраны из ячейки';
								|en = 'picked from storage bin:'; fa = 'picked from storage bin:';
								|it = 'selezionati dalla cella';
								|pl = 'wybrane z komórki';
								|tr = 'hücreden seçildi'");
			Parameter_2 = NStr("vi = 'Chọn các mục không được chọn từ các ô khác?';
								|ru = 'Отобрать неотобранные товары из других ячеек?';
								|en = 'Do you want to pick the lacking items from another storage bin?'; fa = 'Do you want to pick the lacking items from another storage bin?';
								|it = 'Selezionare i prodotti non selezionati da altre celle?';
								|pl = 'Wybrać nie wybrane wiersze pozycji z innych komórek?';
								|tr = 'Diğer hücrelerden seçili olmayan ürünler seçilsin mi?'");
		Else
			Parameter_1 = NStr("vi = 'xếp vào ô';
								|ru = 'размещены в ячейку';
								|en = 'put away in storage bin:'; fa = 'put away in storage bin:';
								|it = 'collocati nella cella';
								|pl = 'umieszczone w komórce';
								|tr = 'hücreye yerleştirildi'");
			Parameter_2 = NStr("vi = 'Đặt các mục không thay thế trong các ô khác?';
								|ru = 'Разместить неразмещенные товары в других ячейках?';
								|en = 'Do you want to put the rest of the items into another storage bin?'; fa = 'Do you want to put the rest of the items into another storage bin?';
								|it = 'Collocare i prodotti non collocati nelle altre celle?';
								|pl = 'Umieścić nieumieszczone wiersze pozycji w innych komórkach?';
								|tr = 'Yerleştirilmemiş ürünler diğer hücrelere yerleştirilsin mi?'");
		EndIf;
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageText, Parameter_1,
			?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell),
			Parameter_2);
		
		Buttons = New ValueList;
		Buttons.Add(NewDialogButton("SelectGoodsFromOtherBins", NStr("vi = 'Có';
																	|ru = 'Да';
																	|en = 'Yes'; fa = 'بله';
																	|it = 'Sì';
																	|pl = 'Tak';
																	|tr = 'Evet'")));
		Buttons.Add(NewDialogButton("CancelGoodsPickingFromOtherBins",
			NStr("vi = 'Không';
				|ru = 'Нет';
				|en = 'No'; fa = 'خیر';
				|it = 'Non ci sono';
				|pl = 'Nie';
				|tr = 'Hayır'")));
		
		ShowMessageDialog(Form, QueryText, Buttons);
		
	EndIf;
	
EndProcedure

// Terminates the execution of the inventory job. When scanning products, the scanned products
// are transferred to the tabular parts of the documents. when typing, new warehouse tasks are created.
// The necessary statuses are set for documents, and documents are processed.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* ScannedGoods - FormDataCollectionItem - table of scanned products.
//
Procedure CompleteWarehouseTask(Form) Export
	
	DataProcessorObject = Form.Object;
	Job = Form.ModeSettings.Job;
	ModeSettings = Form.ModeSettings;
	WebServiceMode = Form.WebServiceMode;
	Form.Job = ModeSettings.Job;
	JobType = ModeSettings.JobType;
	
	ThereAreProductsNotScanned = ThereAreProductsNotScanned(Form);
	ThereAreScannedProducts = ThereAreScannedProducts(Form);
	
	// If the task has not even started running yet, then it is not completed, 
	// but canceled - the task is transferred to the original status.
	If JobType = "PickingCheck" Then
		
		If Not ThereAreScannedProducts Then
			CancelJobExecution(Form);
			Return;
		EndIf;
		
	EndIf;
	
	VTScannedProducts = Form.ScannedGoods.Unload();
	
	If JobType = "Move" Then
		
		If WebServiceMode Then
			JobParameters = WorkplaceOfWarehouseWorkerXDTO.CompleteWarehouseTask(Form, Job);
		Else
			EndParameters = 
				WorkplaceOfWarehouseWorkerApplicationInterface.NewCompleteWarehouseTaskParameters();
			EndParameters.Job = Job;
			EndParameters.VTScannedProducts = VTScannedProducts;
			EndParameters.GoodsForScanning = Form.GoodsForScanning;
			EndParameters.ReceivingArea = ModeSettings.ReceivingArea;
			EndParameters.ShippingZone = ModeSettings.ShippingZone;
			EndParameters.SelectionScanned = ModeSettings.SelectionScanned;
			JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteWarehouseTask(
				EndParameters);
			EndIf;
			
	EndIf;
	
	If JobType = "Recalculate" Then
		
		// If you scanned a cell, but did not scan the item, then the cell is empty.
		// Let's write down an empty cell or find an un-scanned item in this cell and
		// write it down with zero remainder.
		VTProductsForScanning = Form.FormAttributeToValue("GoodsForScanning");
		
		If ValueIsFilled(Form.CurrentScanningLine.SKCell)
			And Not ValueIsFilled(Form.CurrentScanningLine.SKProducts) Then
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("Cell", Form.CurrentScanningLine.Cell);
			
			ArrayOfProductsToScanByCurCell = VTProductsForScanning.FindRows(TheStructureOfTheSearch);
			
			For Each ArrayRow In ArrayOfProductsToScanByCurCell Do
				NewRow = VTScannedProducts.Add();
				FillPropertyValues(NewRow, ArrayRow, , "NumberOfPackagingsScanned");
				NewRow = Form.ScannedGoods.Add();
				FillPropertyValues(NewRow, ArrayRow, , "NumberOfPackagingsScanned");
			EndDo;
			
		// If the item was scanned, then in the current cell we will find the item that was planned 
		// to be scanned, but not scanned, and write it down with zero remainder.
		ElsIf ValueIsFilled(Form.CurrentScanningLine.SKCell)
			And ValueIsFilled(Form.CurrentScanningLine.SKProducts) Then
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("Cell", Form.CurrentScanningLine.Cell);
			
			ArrayOfProductsToScanByCurCell = VTProductsForScanning.FindRows(TheStructureOfTheSearch);
			
			For Each RowOfArrayOfProductsToScan In ArrayOfProductsToScanByCurCell Do
				
				Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
				FillPropertyValues(Filter, RowOfArrayOfProductsToScan);
				
				RowsArray = VTScannedProducts.FindRows(Filter);
				
				If RowsArray.Count() = 0 Then
					NewRow = VTScannedProducts.Add();
					FillPropertyValues(NewRow, RowOfArrayOfProductsToScan, , "NumberOfPackagingsScanned");
					NewRow = Form.ScannedGoods.Add();
					FillPropertyValues(NewRow, RowOfArrayOfProductsToScan, , "NumberOfPackagingsScanned");
				Else
					Continue;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	If JobType = "Filter"
		Or JobType = "Recalculate"
		Or JobType = "Location"
		Or JobType = "PickingCheck" Then
		
		If WebServiceMode Then
			JobParameters = WorkplaceOfWarehouseWorkerXDTO.CompleteWarehouseTask(Form, Job);
		Else
			EndParameters = 
				WorkplaceOfWarehouseWorkerApplicationInterface.NewCompleteWarehouseTaskParameters();
				EndParameters.Job = Job;
			EndParameters.VTScannedProducts = VTScannedProducts;
			EndParameters.GoodsForScanning = Form.GoodsForScanning;
			JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteWarehouseTask(
				EndParameters);
		EndIf;
		
	EndIf;
	
	// Display a message about the completion of the task.
	Buttons = New ValueList;
	AddButtonToGoToTaskSelection(Buttons, ModeSettings.JobType);
	
	If JobParameters.ReturnCode = 0 Then
		MessageTitle = NStr("vi = 'Chưa thực hiện nhiệm vụ';
							|ru = 'Задание не выполнено';
							|en = 'Task not completed'; fa = 'Task not completed';
							|it = 'Task non eseguito';
							|pl = 'Zadanie nie wykonane';
							|tr = 'Görev gerçekleştirilemedi'");
		MessageText = NStr("vi = 'Khi kết thúc nhiệm vụ, đã xảy ra lỗi. Không thể kết chuyển nhiệm vụ. 
			|Hãy liên hệ với người quản trị.';
			|ru = 'При завершении задания произошла ошибка. Не удалось провести задание. 
			|Обратитесь к администратору.';
			|en = 'Task failed with error. Cannot post the task.
			|Please contact the administrator.'; fa = 'Task failed with error. Cannot post the task.
			|Please contact the administrator.';
			|it = 'Si è verificato un errore durante il completamento del task. Non è stato possibile registrare il task. 
			|Rivolgetevi all''amministratore.';
			|pl = 'Podczas zakończenia zadania wystąpił błąd. Nie udało się zatwierdzić zadanie.
			|Skontaktuj się z administratorem.';
			|tr = 'Görev tamamlanırken hata oluştu. Görev kaydedilemedi. 
			|Yöneticiyle iletişime geç.'");
	Else
		
		MessageTitle = NStr("vi = 'Nhiệm vụ đã thực hiện';
							|ru = 'Задание выполнено';
							|en = 'Task is completed'; fa = 'Task is completed';
							|it = 'Task eseguito';
							|pl = 'Zadanie wykonane';
							|tr = 'Görev tamamlandı'");
		
		If JobType = "Filter" Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kết thúc thực hiện nhiệm vụ. Hàng hóa đã lấy ra cần đưa vào khu vực giao hàng ""%1"".';
					|ru = 'Выполнение задания завершено. Отобранные товары следует отнести в зону отгрузки ""%1"".';
					|en = 'Task is completed. Please deliver the items to the outbound area %1.'; fa = 'Task is completed. Please deliver the items to the outbound area %1.';
					|it = 'Esecuzione del task completata. Le merci selezionate devono essere portate nell''area di spedizione ""%1"".';
					|pl = 'Wykonanie zadania jest zakończone. Wybrane wiersze pozycji należy zanieść do strefy wysyłki ""%1"".';
					|tr = 'Görev tamamlandı. Seçilen ürünler ""%1"" yükleme alanına götürülmelidir.'"),
				?(WebServiceMode, ModeSettings.NameOfShippingArea, ModeSettings.ShippingZone));
			
		ElsIf JobType = "Location" Then
			
			If ThereAreProductsNotScanned Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã hoàn tất việc thực hiện nhiệm vụ. Hàng hóa chưa được sắp xếp cần chuyển đến khu vực nhập hàng ""%1""';
						|ru = 'Выполнение задания завершено. Неразмещенные товары следует отнести в зону приемки ""%1""';
						|en = 'Task is completed. Please deliver the items to the inbound area %1.'; fa = 'Task is completed. Please deliver the items to the inbound area %1.';
						|it = 'Esecuzione del task completata. Le merci non collocate devono essere portate nell''area di accettazione ""%1""';
						|pl = 'Wykonanie zadania jest zakończone. Nieumieszczone wiersze pozycji należy zanieść do strefy odbioru ""%1""';
						|tr = 'Görev tamamlandı. Yerleştirilmeyen ürünler ""%1"" boşaltma alanına götürülmelidir'"),
					?(WebServiceMode, ModeSettings.NameOfAcceptanceZone, ModeSettings.ReceivingArea));
					
			Else
				MessageText = NStr("vi = 'Đã kết thúc thực hiện nhiệm vụ.';
									|ru = 'Выполнение задания завершено.';
									|en = 'Task completed.'; fa = 'Task completed.';
									|it = 'Esecuzione del task completata.';
									|pl = 'Wykonanie zadania jest zakończone.';
									|tr = 'Görev tamamlandı.'");
			EndIf;
			
		ElsIf JobType = "Move" Then
			
			CountPicked = 0;
			CountPlaced = 0;
			
			For Each RowOfGoods In DataProcessorObject.GoodsFilter Do
				CountPicked = CountPicked + RowOfGoods.NumberOfPackagesPicked *
					RowOfGoods.ZoomRatio;
			EndDo;
			
			For Each RowOfGoods In Form.GoodsForScanning Do
				CountPlaced = CountPlaced + RowOfGoods.NumberOfPackagingsScanned *
					RowOfGoods.ZoomRatio;
			EndDo;
			
			If (CountPlaced <> CountPicked) Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã kết thúc thực hiện nhiệm vụ. 
						|Cần đưa những hàng hóa đã lấy ra, nhưng chưa xếp vào 
						|vào khu vực nhận hàng: ""%1""';
						|ru = 'Выполнение задания завершено. 
						|Отобранные, но не размещенные товары 
						|следует отнести в зону приемки: ""%1""';
						|en = 'Task is completed.
						|Please deliver the rest of the items to the inbound area:
						|%1.'; fa = 'Task is completed.
						|Please deliver the rest of the items to the inbound area:
						|%1.';
						|it = 'Esecuzione del task completata. 
						| Le merci selezionate ma non collocate
						| devono essere portate nell''area di accettazione: ""%1""';
						|pl = 'Wykonanie zadania jest zakończone. 
						|Wybrane, ale nie umieszczone wiersze pozycji
						|należy zanieść do strefy odbioru: ""%1""';
						|tr = 'Görev tamamlandı. 
						|Seçili ancak yerleştirilmemiş ürünler 
						|boşaltma alanına götürülmelidir: ""%1""'"), 
					?(WebServiceMode, ModeSettings.NameOfAcceptanceZone, ModeSettings.ReceivingArea));
				
			Else
				MessageText = NStr("vi = 'Đã kết thúc thực hiện nhiệm vụ.';
									|ru = 'Выполнение задания завершено.';
									|en = 'Task completed.'; fa = 'Task completed.';
									|it = 'Esecuzione del task completata.';
									|pl = 'Wykonanie zadania jest zakończone.';
									|tr = 'Görev tamamlandı.'");
			EndIf;
			
		ElsIf JobType = "Recalculate"
			Or JobType = "PickingCheck" Then
			
			MessageText = NStr("vi = 'Đã kết thúc thực hiện nhiệm vụ.';
								|ru = 'Выполнение задания завершено.';
								|en = 'Task completed.'; fa = 'Task completed.';
								|it = 'Esecuzione del task completata.';
								|pl = 'Wykonanie zadania jest zakończone.';
								|tr = 'Görev tamamlandı.'");
			
		EndIf;
		
		ClearScanItems(Form);
		
	EndIf;
	
	Form.Job = Job;
	ModeSettings.Job = Job;
	
	ShowMessageDialog(Form, MessageText, Buttons, MessageTitle);
	
EndProcedure

// Performs the completion of warehouse tasks. Depending on the type
// of task and the degree of its completion, additional processing procedures are called.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure FinishJobExecution(Form) Export
	
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	JobType = Form.ModeSettings.JobType;
	
	If ThisIsSetOfGoods Then
		If JobType = "Location" Then
			CompleteTaskNewPlacement(Form);
		ElsIf JobType = "Receiving" Then
			CompleteAcceptanceTask(Form);
		EndIf;
	Else
		If JobType = "Move" Then
			FinishTask(Form);
		ElsIf JobType = "PickingCheck" Then
			CompleteTaskCheckSelection(Form);
		Else
			CompleteWarehouseTask(Form);
		EndIf;
	EndIf;
	
EndProcedure

// Returns an indication that this cell is the last one in the task.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - True, a sign that the current warehouse cell is the last one in the warehouse task.
//
Function ThisIsLastCell(Form) Export
	
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If CurrentScanningLine = Undefined Then
		Return False;
	EndIf;
	
	ThisIsLastOne_ = (CurrentScanningLine.NumberOfBins = CurrentScanningLine.CellNumber);
	
	Return ThisIsLastOne_;
	
EndFunction

// Cancels the current warehouse task and returns it to its original status.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CancelJobExecution(Form) Export
	
	If Not ValueIsFilled(Form.ModeSettings.Job) Then
		GoToWarehouseOperationSelection(Form);
		Return;
	EndIf;
	
	WebServiceMode = Form.WebServiceMode;
	ModeSettings = Form.ModeSettings;
	Job = ModeSettings.Job;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	SourceExecutor = ModeSettings.SourceExecutor;
	
	If WebServiceMode Then
		JobParameters = WorkplaceOfWarehouseWorkerXDTO.CancelJobExecution(Form, Job);
	Else
		JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CancelJobExecution(Job,
			SourceExecutor, JobType);
	EndIf;
	
	If ThisIsSetOfGoods
		And JobType = "Location" Then
		
		Form.CurrentScanningLine = Undefined;
		ClearScanItems(Form);
		InitializeModeParameters(Form);
		
	EndIf;
	
	If JobParameters.ReturnCode = 0 Then
		GoToMainMenuButton_ = NewDialogButton("GoToWarehouseOperationSelection",
			NStr("vi = 'Chuyển đến chọn giao dịch';
				|ru = 'Перейти к выбору операции';
				|en = 'Go to operation selection'; fa = 'Go to operation selection';
				|it = 'Passa alla selezione dell''operazione';
				|pl = 'Przejść do wyboru operacji';
				|tr = 'İşlem seçimine git'"));
		
		ShowMessageDialog(Form, JobParameters.MessageText, GoToMainMenuButton_);
	Else
		If ThisIsSetOfGoods Then
			If JobType = "Location" Then
				GoToWarehouseOperationSelection(Form);
			ElsIf JobType = "Receiving" Then
				GoToTaskSelection(Form, JobType);
			EndIf;
		Else
			ClearScanItems(Form);
			GoToTaskSelection(Form, JobType);
		EndIf;
	EndIf;
	
EndProcedure

// This procedure is called when a task is submitted for acceptance.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** ScanTheProduct - FormButton - a button that executes the discovery of information about the product.
// 			** ScanSeries - FormButton - a button that opens information about the product series.
// 			** TheInscriptionToTake - FormField - information label for the user interface.
// 			** LabelPackaging - FormField - information label for the user interface.
// 			** LabelNumberOfPackages - FormField - information label for the user interface.
// 			** ScanToEnterTheNumber - FormButton - a button that opens a form with a field for entering the quantity
// 															of the scanned product.
//
Procedure GoToTheGoodsReceiving(Form) Export
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	
	ModeSettings.CreatedJob = Undefined;
	ModeSettings.JobType = "Receiving";
	ModeSettings.SetOfProducts_ = True;
	
	Form.ErrorMessage = "";
	Form.CurrentScanningLine = ScanLine();
	
	Form.GoodsForScanning.Clear();
	Form.ScannedGoods.Clear();
	Form.ScannedPackage.GetItems().Clear();
	Form.CellsForScanning.Clear();
	
	CreateQueueOfScanParameters(Form);
	GoToNextScanOption(Form);
	
	// Set the headers of the elements.
	If Form.UsePackingLists Then
		Items.ScanTheProduct.Title = NStr("vi = '<Hàng hóa / Phiếu đóng gói>';
											|ru = '<Товар / Упаковочный лист>';
											|en = '<Inventory/Packing list>'; fa = '<Inventory/Packing list>';
											|it = '<Merce / Distinta di imballaggio>';
											|pl = '<Towar / Lista pakowa>';
											|tr = '<Ürün / Ürün listesi>'");
	EndIf;
	
	Items.ScanSeries.Title = NStr("vi = '<Sê-ri>';
									|ru = '<Серия>';
									|en = '<Batch>'; fa = '<بچ>';
									|it = '<serie>';
									|pl = '<Batch>';
									|tr = '<Parti>'");
	
	Items.TheInscriptionToTake.Title = "";
	Items.LabelPackaging.Title = "";
	Items.LabelNumberOfPackages.Title = "";
	Items.ScanToEnterTheNumber.Title = 0;
	
	DisplayTaskState(Form);
	GoToScanning(Form);
	
EndProcedure

// Called when creating a new warehouse placement task.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** ScanTheProduct - FormButton - a button that executes the discovery of information about the product.
// 			** ScanSeries - FormButton - a button that opens information about the product series.
// 			** TheInscriptionToTake - FormField - information label for the user interface.
// 			** LabelPackaging - FormField - information label for the user interface.
// 			** LabelNumberOfPackages - FormField - information label for the user interface.
// 			** ScanToEnterTheNumber - FormButton - a button that opens a form with a field for entering the quantity
// 															of the scanned product.
//
Procedure CreateANewWarehouseTask(Form) Export
	
	Items = Form.Items;
	
	Form.ModeSettings.CreatedJob  = Undefined;
	Form.ErrorMessage = "";
	Form.CurrentScanningLine = ScanLine();
	Form.ModeSettings.JobType = "Location";
	Form.ModeSettings.SetOfProducts_ = True;
	
	If Not ValueIsFilled(Form.SeriesScanMode) Then
		Form.SeriesScanMode = "ProductAllSeries";
	EndIf;
	
	SetParametersOfScanSchemeElements(Form);
	
	ClearScanItems(Form);
	CreateQueueOfScanParameters(Form);
	
	ResetSignsOfScanningAllParameters(Form);
	SetParameterScanFlag(Form, "Cell", True);
	GoToNextScanOption(Form);
	SetParameterScanFlag(Form, "Products", True);
	
	// Set the headers of the elements.
	Items.ScanTheProduct.Title = NStr("vi = '<Hàng hóa>';
										|ru = '<Товар>';
										|en = '<Item>'; fa = '<قلم>';
										|it = '<merce>';
										|pl = '<Item>';
										|tr = '<Ürün>'");
	Items.ScanSeries.Title = NStr("vi = '<Sê-ri>';
									|ru = '<Серия>';
									|en = '<Batch>'; fa = '<بچ>';
									|it = '<serie>';
									|pl = '<Batch>';
									|tr = '<Parti>'");
	
	Items.TheInscriptionToTake.Title = "";
	Items.LabelPackaging.Title = "";
	Items.LabelNumberOfPackages.Title = "";
	Items.ScanToEnterTheNumber.Title = 0;
	
	SetVisibilityOfScanItems(Form);
	DisplayTaskState(Form);
	GoToScanning(Form);
	
EndProcedure

// Performs the actions necessary for setting the task to work.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace:
// 		* Object - FormDataStructure -:
// 			** SetOfSeries - FormDataCollection -
// 			** Goods - FormDataCollection -
// 			** GoodsFilter - FormDataCollection -
// 			** GoodsPlacement - FormDataCollection -
// 			** ShippedGoods - FormDataCollection -
// 		* GoodsAreSelected - Boolean -.
//	Job - DocumentRef.GoodsReceiptNote, DocumentRef.GoodsIssueNote, DocumentRef.GoodsPickingPlacement, DocumentRef.InventoryRecount - a warehouse task that is being accepted for work.
//	JobParameters - Structure - parameters of the warehouse task. The structure is described in the function 'parameterization ()'
//		of the General module of the Workworkworkerskladaprogrammnyinterface.
//
Procedure TakeTaskToWork(Form, Job, JobParameters = Undefined) Export
	
	Object = Form.Object;
	Form.GoodsAreSelected = False;
	User = Object.User;
	ModeSettings = Form.ModeSettings;
	
	If JobParameters = Undefined Then
		
		If Form.WebServiceMode Then
			JobParameters = WorkplaceOfWarehouseWorkerXDTO.JobParametersWhenAcceptedForWork(Form, Job);
		Else
			JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.JobParametersWhenAcceptedForWork(Job,
				User);
		EndIf;
		
	EndIf;
	
	If JobParameters.ReturnCode = 0 Then
		
		Buttons = New ValueList;
		AddButtonToGoToTaskSelection(Buttons, JobParameters.JobType);
		
		ShowMessageDialog(Form, JobParameters.MessageText, Buttons);
		
		Return;
		
	EndIf;
	
	// Set the mode parameters.
	ModeSettings.Job = Job;
	ModeSettings.SetOfProducts_ = False;
	ModeSettings.SelectionScanned = False;
	ModeSettings.ScanParameter = "";
	ModeSettings.PlacementScanned = False;
	
	// Clear the tabular parts of the form object.
	Object.Goods.Clear();
	Object.GoodsFilter.Clear();
	Object.GoodsPlacement.Clear();
	Object.ShippedGoods.Clear();
	Object.SetOfSeries.Clear();
	
	ReceivingShippingAreas = "";
	AttributesToExclude = "Goods, GoodsFilter, GoodsPlacement, ShippedGoods";
	
	If Form.WebServiceMode Then
		If ModeSettings.JobType = "Filter" Then
			ReceivingShippingAreas = ReceivingShippingAreas + "ReceivingArea, NameOfAcceptanceZone";
		ElsIf ModeSettings.JobType = "Location" Then
			ReceivingShippingAreas = ReceivingShippingAreas + "ShippingZone, NameOfShippingArea";
		ElsIf ModeSettings.JobType = "Move" Then
			ReceivingShippingAreas = ReceivingShippingAreas + "ReceivingArea, ShippingZone, NameOfAcceptanceZone,
				|NameOfShippingArea";
		EndIf;
	Else
		If ModeSettings.JobType = "Filter" Then
			ReceivingShippingAreas = ReceivingShippingAreas + "ReceivingArea";
		ElsIf ModeSettings.JobType = "Location" Then
			ReceivingShippingAreas = ReceivingShippingAreas + "ShippingZone";
		ElsIf ModeSettings.JobType = "Move" Then
			ReceivingShippingAreas = ReceivingShippingAreas + "ReceivingArea, ShippingZone";
			ModeSettings.ShippingZone = Catalogs.StorageBins.DefaultShippingZone(Form.Object.Warehouse, Form.Object.Premise);
			ModeSettings.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Form.Object.Warehouse, Form.Object.Premise);
		EndIf;
	EndIf;
	
	FillPropertyValues(ModeSettings, JobParameters, , ReceivingShippingAreas);
	FillPropertyValues(Object, JobParameters, , AttributesToExclude);
	
	// Fill in the tabular parts of the object.
	If ModeSettings.JobType = "Filter" Then
		CommonClientServer.SupplementTable(JobParameters.GoodsFilter, Object.GoodsFilter);
	ElsIf ModeSettings.JobType = "Recalculate" Then
		CommonClientServer.SupplementTable(JobParameters.Goods, Object.Goods);
	ElsIf ModeSettings.JobType = "Location" Then
		CommonClientServer.SupplementTable(JobParameters.GoodsPlacement, Object.GoodsPlacement);
	ElsIf ModeSettings.JobType = "Move" Then
		CommonClientServer.SupplementTable(JobParameters.GoodsFilter, Object.GoodsFilter);
		CommonClientServer.SupplementTable(JobParameters.GoodsPlacement, Object.GoodsPlacement);
	ElsIf ModeSettings.JobType = "PickingCheck" Then
		CommonClientServer.SupplementTable(JobParameters.ShippedGoods, Object.ShippedGoods);
	EndIf;
	
	// Get the parameters of the task items.
	GoodsParameters = TaskProductParameters(Form);
	FillPropertyValues(ModeSettings, GoodsParameters);
	
	// Set the values of the details needed to perform the scan.
	Form.ErrorMessage = "";
	Form.CurrentScanningLine = Undefined;
	
	FillInDataForScanningJob(Form);
	FillInRemainingItemsInCell(Form);
	FillInItemsForRecalculation(Form);
	
	Form.ScannedGoods.Clear();
	Form.ScannedPackage.GetItems().Clear();
	
	SetInitialStateOfJob(Form);
	SetVisibilityOfScanItems(Form);
	SetDefaultScanScheme(Form);
	SetParametersForItemsInWarehouseTaskProcessingOrder(Form);
	
	If ModeSettings.JobType = "Recalculate" Then
		
		MessageText = NStr("vi = 'Hãy quét tất cả hàng hóa trong ô, 
		|sau đó nhấn nút ""Tiếp theo"" để chuyển sang ô tiếp theo.';
		|ru = 'Отсканируйте все товары в ячейке, 
		|затем нажмите кнопку ""Далее"" для перехода к следующей ячейке.';
		|en = 'Scan all items in the storage bin.
		|Then, select ""Next"" to proceed to the next bin.'; fa = 'Scan all items in the storage bin.
		|Then, select ""Next"" to proceed to the next bin.';
		|it = 'Scansionate tutte le merci nella cella, 
		| poi premete il pulsante ""Avanti"" per passare alla cella successiva.';
		|pl = 'Zeskanuj wszystkie wiersze pozycji w komórce, 
		|następnie kliknij przycisk ""Dalej"", aby przejść do następnej komórki.';
		|tr = 'Hücredeki tüm ürünleri tara, 
		|ardından sonraki hücreye geçmek için ""İleri"" düğmesini tıkla.'");
		
		Buttons = New ValueList;
		
		GoToScanButton = NewDialogButton(
			"GoToScanning", 
			NStr("vi = 'Chuyển đến 
			|quét ảnh';
			|ru = 'Перейти 
			|к сканированию';
			|en = 'Go to
			|scanning'; fa = 'Go to
			|scanning';
			|it = 'Passa 
			| alla scansione';
			|pl = 'Przejdź 
			|do skanowania';
			|tr = 'Taramaya 
			|git'"));
		
		Buttons.Add(GoToScanButton);
		
		ShowMessageDialog(Form, MessageText, Buttons);
		
	ElsIf ModeSettings.JobType = "Receiving" Then
		
		Buttons = New ValueList;
		
		If Form.UsePackingLists Then
			MessageText = NStr("vi = 'Hãy quét mã vạch hàng hóa hoặc phiếu đóng gói, 
				|sau đó nhấn nút ""Tiếp theo"" để kết thúc nhập hàng.';
				|ru = 'Отсканируйте штрихкоды товаров или упаковочных листов, 
				|затем нажмите кнопку ""Далее"" для завершения приемки.';
				|en = 'Scan items or packing lists.
				|Then, click ""Next"" to finish.'; fa = 'Scan items or packing lists.
				|Then, click ""Next"" to finish.';
				|it = 'Scansionate i codici a barre delle merci o distinte di imballaggio, 
				|poi premete il pulsante ""Avanti"" per terminare l''accettazione.';
				|pl = 'Zeskanuj kody kreskowe towarów lub list pakowych, 
				|następnie kliknij przycisk ""Dalej"", aby zakończyć odbiór.';
				|tr = 'Ürünlerin veya ürün listelerinin barkodlarını tarayın,
				|ardından kabulü tamamlamak için ""İleri"" düğmesini tıklayın.'");
			
		Else
			MessageText = NStr("vi = 'Hãy quét tất cả hàng hóa, 
				|sau đó nhấn nút ""Tiếp theo"" để kết thúc nhập hàng.';
				|ru = 'Отсканируйте все товары, 
				|затем нажмите кнопку ""Далее"" для завершения приемки.';
				|en = 'Scan all items.
				|Then, select ""Next"" to finish.'; fa = 'Scan all items.
				|Then, select ""Next"" to finish.';
				|it = 'Scansionate tutte le merci, 
				| poi premete il pulsante ""Avanti"" per terminare l''accettazione.';
				|pl = 'Zeskanuj wszystkie wiersze pozycji, 
				|następnie kliknij przycisk ""Dalej"", aby zakończyć odbiór.';
				|tr = 'Tüm ürünleri tarayın, 
				|ardından kabulü tamamlamak için ""İleri"" düğmesini tıklayın.'");
		EndIf;
		
		GoToProductAcceptanceButton = NewDialogButton(
				"GoToTheGoodsReceiving",
				NStr("vi = 'Chuyển đến quét ảnh';
					|ru = 'Перейти к сканированию';
					|en = 'Go to scanning'; fa = 'رفتن به اسکن';
					|it = 'Passa alla scansione';
					|pl = 'Przejdź do skanowania';
					|tr = 'Taramaya git'"));
				
		Buttons.Add(GoToProductAcceptanceButton);
		
		ShowMessageDialog(Form, MessageText, Buttons);
		
	ElsIf ModeSettings.JobType = "PickingCheck" Then
		
		MessageText = 
			NStr("vi = 'Hãy quét tất cả hàng hóa, 
			|sau đó nhấn nút ""Tiếp theo"" để kết thúc kiểm tra.';
			|ru = 'Отсканируйте все товары, 
			|затем нажмите кнопку ""Далее"" для завершения проверки.';
			|en = 'Scan all goods.
			|Then, select ""Next"" to finish.'; fa = 'Scan all goods.
			|Then, select ""Next"" to finish.';
			|it = 'Scansionate tutte le merci, 
			|poi premete il pulsante ""Avanti"" per terminare la verifica.';
			|pl = 'Zeskanuj wszystkie wiersze pozycji, 
			|następnie kliknij przycisk ""Dalej"", aby zakończyć weryfikację.';
			|tr = 'Tüm ürünleri tarayın, 
			|ardından taramayı tamamlamak için ""İleri""yi tıklayın.'");
		
		Buttons = New ValueList;
		
		GoToAcceptanceButton = NewDialogButton(
			"GoToScanning",
			NStr("vi = 'Chuyển đến quét ảnh';
				|ru = 'Перейти к сканированию';
				|en = 'Go to scanning'; fa = 'رفتن به اسکن';
				|it = 'Passa alla scansione';
				|pl = 'Przejdź do skanowania';
				|tr = 'Taramaya git'"));
		
		Buttons.Add(GoToAcceptanceButton);
		
		ShowMessageDialog(Form, MessageText, Buttons);
		
	Else
		
		GoToScanning(Form);
		
	EndIf;
	
EndProcedure

// Called when the transition to scanning of the goods. Switches to the 
// scan page and calls the procedures for setting the header
// of the scan elements.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToScanning(Form) Export
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	SelectionScanned = ModeSettings.SelectionScanned;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If Not ThisIsSetOfGoods
		And Not ModeSettings.ClosingForm_ Then
		CreateQueueOfScanParameters(Form);
		Form.CurrentScanningLine = ScanLine();
	EndIf;
	
	If ThisIsSetOfGoods Then
		
		Items.ScanningToCheckTheBoxToRecalculate.Visible = False;
		If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
			Items.ButtonSeparatorScan.Visible = True;
		EndIf;
		
		If JobType = "Location" Then
			SetParametersForScanItems(Form);
			GoToPage3(Form,"ScanPage");
			DisplayTaskState(Form);
		ElsIf JobType = "Receiving" Then
			If ModeSettings.ClosingForm_ Then
				ModeSettings.ClosingForm_ = False;
			Else
				CreateQueueOfScanParameters(Form);
				Form.CurrentScanningLine = ScanLine();
				GoToNextScanOption(Form);
			EndIf;
			
			SetParametersForScanItems(Form);
			GoToPage3(Form,"ScanPage");
			DisplayTaskState(Form);
		Else
			If ModeSettings.ClosingForm_ Then
				ModeSettings.ClosingForm_ = False;
			Else
				GoToNextScanOption(Form);
			EndIf;
			
			SetParametersForScanItems(Form);
			GoToPage3(Form,"ScanPage");
			DisplayTaskState(Form);
		EndIf;
		
		Return;
		
	Else
		
		If JobType = "Recalculate" Then
			
			If ModeSettings.ClosingForm_ Then
				ModeSettings.ClosingForm_ = False;
			Else
				GoToTheNextBin(Form);
			EndIf;
			
			Items.ScanningToCheckTheBoxToRecalculate.Visible = True;
			
		ElsIf JobType = "Move" Then
			
			If ModeSettings.ClosingForm_ Then
				ModeSettings.ClosingForm_ = False;
			Else
				
				If SelectionScanned Then
					If ThisIsProcessingOrderOfItemCell Then
						SwitchToProductScanStandbyMode(Form);
						GoToNextScanOption(Form);
					Else
						GoToNextScanLine(Form);
					EndIf;
				Else
					GoToNextScanLine(Form);
				EndIf;
				
			EndIf;
			
			Items.ScanningToCheckTheBoxToRecalculate.Visible = True;
			
		ElsIf JobType = "PickingCheck" Then
			
			If ModeSettings.ClosingForm_ Then
				ModeSettings.ClosingForm_ = False;
			Else
				GoToNextScanLine(Form);
			EndIf;
			
			Items.ScanningToCheckTheBoxToRecalculate.Visible = False;
			
		ElsIf JobType = "Location" Then
			
			If ModeSettings.ClosingForm_ Then
				ModeSettings.ClosingForm_ = False;
			Else
				
				If ThisIsProcessingOrderOfItemCell Then
					SwitchToProductScanStandbyMode(Form);
					GoToNextScanOption(Form);
				Else
					GoToNextScanLine(Form);
				EndIf;
				
			EndIf;
			
			Items.ScanningToCheckTheBoxToRecalculate.Visible = True;
			
		Else
			
			If ModeSettings.ClosingForm_ Then
				ModeSettings.ClosingForm_ = False;
			Else
				GoToNextScanLine(Form);
			EndIf;
			
			Items.ScanningToCheckTheBoxToRecalculate.Visible = True;
			
		EndIf;
	EndIf;
	
	If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
		If Items.ScanningToCheckTheBoxToRecalculate.Visible Then
			Items.ButtonSeparatorScan.Visible = False;
		Else
			Items.ButtonSeparatorScan.Visible = True;
		EndIf;
	EndIf;
	
	SetParametersForScanItems(Form);
	GoToPage3(Form,"ScanPage");
	DisplayTaskState(Form);
	
EndProcedure

// Moves the task execution flow to the next cell.
// 
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToTheNextScanningBin(Form) Export
	
	ModeSettings = Form.ModeSettings;
	WebServiceMode = Form.WebServiceMode;
	JobType = ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If CurrentScanningLine.CellNumber = Form.CellsForScanning.Count() Then
		
		If JobType = "Filter" Then
			If ValueIsFilled(CurrentScanningLine.SKProducts) Then
				MessageText = NStr("vi = 'Ô ""%1"" 
					|là cuối cùng trong nhiệm vụ lọc.
					|Kết thúc thực hiện lọc hàng hóa?';
					|ru = 'Ячейка ""%1""
					|последняя в задании на отбор.
					|Завершить выполнение отбора товаров?';
					|en = 'The %1 storage bin
					|is the last in the picking job.
					|Complete goods picking?'; fa = 'The %1 storage bin
					|is the last in the picking job.
					|Complete goods picking?';
					|it = 'Ячейка ""%1""
					|последняя в задании на отбор.
					|Завершить выполнение отбора товаров?';
					|pl = 'The %1 storage bin
					|is the last in the picking job.
					|Complete goods picking?';
					|tr = '""%1"" hücresi 
					| için görevde sonuncudur.
					|Ürün filtresi kapatılsın mı?'");
			Else
				MessageText = NStr("vi = 'Ô hàng ""%1"" 
					|là cuối cùng trong nhiệm vụ lọc,
					|và trong đó chưa quét mặt hàng nào.
					|Kết thúc thực hiện lọc hàng hóa?';
					|ru = 'Ячейка ""%1""
					|последняя в задании на отбор,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение отбора товаров?';
					|en = 'The %1 storage bin
					|is the last in the picking job,
					|and no goods are scanned in it.
					|Complete goods picking?'; fa = 'The %1 storage bin
					|is the last in the picking job,
					|and no goods are scanned in it.
					|Complete goods picking?';
					|it = 'Ячейка ""%1""
					|последняя в задании на отбор,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение отбора товаров?';
					|pl = 'The %1 storage bin
					|is the last in the picking job,
					|and no goods are scanned in it.
					|Complete goods picking?';
					|tr = '""%1"" hücresi filtredeki görevin 
					|konumundaki son hücredir ve 
					|hiçbir öğe taranmamıştır.
					|Ürün filtresi kapatılsın mı?'");
			EndIf;
			PresentationOfGoToScanDialogButton = NStr("vi = 'Tiếp tục lấy ra hàng hóa';
														|ru = 'Продолжить отбор товаров';
														|en = 'Resume picking job'; fa = 'Resume picking job';
														|it = 'Продолжить отбор товаров';
														|pl = 'Kontynuuj wybór towarów';
														|tr = 'Ürünleri filtrelemeye devam et'");
		ElsIf JobType = "Location" Then
			If ValueIsFilled(CurrentScanningLine.SKProducts) Then
				MessageText = NStr("vi = 'Ô ""%1"" 
					|là cuối cùng trong nhiệm vụ sắp xếp.
					|Kết thúc thực hiện sắp xếp hàng hóa?';
					|ru = 'Ячейка ""%1"" 
					|последняя в задании на размещение.
					|Завершить выполнение размещения товаров?';
					|en = 'The %1 storage bin
					|is the last in the put-away task.
					|Complete goods put-away?'; fa = 'The %1 storage bin
					|is the last in the put-away task.
					|Complete goods put-away?';
					|it = 'Ячейка ""%1"" 
					|последняя в задании на размещение.
					|Завершить выполнение размещения товаров?';
					|pl = 'The %1 storage bin
					|is the last in the put-away task.
					|Complete goods put-away?';
					|tr = '""%1"" hücresi,
					|yerleştirme görevinde son hücredir.
					|Ürünlerin yerleştirilmesi işlemi tamamlansın mı?'");
			Else
				MessageText = NStr("vi = 'Ô hàng ""%1"" 
					|là cuối cùng trong nhiệm vụ sắp xếp,
					|và trong đó chưa quét mặt hàng nào.
					|Kết thúc thực hiện sắp xếp hàng hóa?';
					|ru = 'Ячейка ""%1"" 
					|последняя в задании на размещение,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение размещения товаров?';
					|en = 'The %1 storage bin
					|is the last in the put-away task,
					|and no goods are scanned in it.
					|Complete goods put-away?'; fa = 'The %1 storage bin
					|is the last in the put-away task,
					|and no goods are scanned in it.
					|Complete goods put-away?';
					|it = 'Ячейка ""%1"" 
					|последняя в задании на размещение,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение размещения товаров?';
					|pl = 'The %1 storage bin
					|is the last in the put-away task,
					|and no goods are scanned in it.
					|Complete goods put-away?';
					|tr = 'Ячейка ""%1"" 
					|последняя в задании на размещение,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение размещения товаров?'");
			EndIf;
			PresentationOfGoToScanDialogButton = NStr("vi = 'Tiếp tục sắp xếp hàng hóa';
														|ru = 'Продолжить размещение товаров';
														|en = 'Resume put-away task'; fa = 'Resume put-away task';
														|it = 'Продолжить размещение товаров';
														|pl = 'Resume put-away task';
														|tr = 'Ürünlerin yerleştirilmelerini devam ettir'");
		ElsIf JobType = "Move" Then
			If ValueIsFilled(CurrentScanningLine.SKProducts) Then
				MessageText = NStr("vi = 'Ô ""%1"" 
					|là cuối cùng trong nhiệm vụ sắp xếp.
					|Kết thúc thực hiện sắp xếp hàng hóa?';
					|ru = 'Ячейка ""%1"" 
					|последняя в задании на перемещение.
					|Завершить выполнение перемещения товаров?';
					|en = 'The %1 storage bin
					|is the last in the transfer task.
					|Complete goods transfer?'; fa = 'The %1 storage bin
					|is the last in the transfer task.
					|Complete goods transfer?';
					|it = 'Ячейка ""%1"" 
					|последняя в задании на перемещение.
					|Завершить выполнение перемещения товаров?';
					|pl = 'The %1 storage bin
					|is the last in the transfer task.
					|Complete goods transfer?';
					|tr = '""%1"" 
					|hücresi, yerleştirme görevindeki son hücredir.
					|Ürün hareketi tamamlansın mı?'");
			Else
				MessageText = NStr("vi = 'Ô hàng ""%1"" 
					|là cuối cùng trong nhiệm vụ sắp xếp,
					|và trong đó chưa quét mặt hàng nào.
					|Kết thúc thực hiện sắp xếp hàng hóa?';
					|ru = 'Ячейка ""%1"" 
					|последняя в задании на перемещение,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение перемещения товаров?';
					|en = 'The %1 storage bin
					|is the last in the transfer task,
					|and no goods are scanned in it.
					|Complete goods transfer?'; fa = 'The %1 storage bin
					|is the last in the transfer task,
					|and no goods are scanned in it.
					|Complete goods transfer?';
					|it = 'Ячейка ""%1"" 
					|последняя в задании на перемещение,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение перемещения товаров?';
					|pl = 'The %1 storage bin
					|is the last in the transfer task,
					|and no goods are scanned in it.
					|Complete goods transfer?';
					|tr = '""%1"" hücresi görevdeki 
					|konumundaki son hücredir ve 
					|hiçbir öğe taranmadı.
					|Öğeyi bitirmek istiyor musunuz?'");
			EndIf;
			PresentationOfGoToScanDialogButton = NStr("vi = 'Tiếp tục điều chuyển hàng hóa nội bộ';
														|ru = 'Продолжить перемещение товаров';
														|en = 'Resume transfer task'; fa = 'Resume transfer task';
														|it = 'Продолжить перемещение товаров';
														|pl = 'Resume transfer task';
														|tr = 'Mal transferine devam et'");
		ElsIf JobType = "Recalculate" Then
			If ValueIsFilled(CurrentScanningLine.SKProducts) Then
				MessageText = NStr("vi = 'Ô ""%1"" 
					|là cuối cùng trong nhiệm vụ sắp xếp.
					|Kết thúc thực hiện sắp xếp hàng hóa?';
					|ru = 'Ячейка ""%1"" 
					|последняя в задании на пересчет.
					|Завершить выполнение пересчета товаров?';
					|en = 'Storage bin ""%1"" 
					|is the last one in the recount job.
					|Finish the inventory count?'; fa = 'Storage bin ""%1"" 
					|is the last one in the recount job.
					|Finish the inventory count?';
					|it = 'Ячейка ""%1"" 
					|последняя в задании на пересчет.
					|Завершить выполнение пересчета товаров?';
					|pl = 'Storage bin ""%1"" 
					|is the last one in the recount job.
					|Finish the inventory count?';
					|tr = '""%1"" hücresi,
					|stok sayımı görevindeki son hücredir.
					|Ürünlerin stok sayımı işlemi tamamlansın mı?'");
			Else
				MessageText = NStr("vi = 'Ô hàng ""%1"" 
					|là cuối cùng trong nhiệm vụ kiểm đếm,
					|và trong đó chưa quét mặt hàng nào.
					|Kết thúc thực hiện kiểm đếm hàng hóa?';
					|ru = 'Ячейка ""%1"" 
					|последняя в задании на пересчет,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение пересчета товаров?';
					|en = 'Storage bin ""%1""
					|is the last one in the recount task.
					|No goods are scanned in the storage bin.
					|Do you want to finish the task?'; fa = 'Storage bin ""%1""
					|is the last one in the recount task.
					|No goods are scanned in the storage bin.
					|Do you want to finish the task?';
					|it = 'Ячейка ""%1"" 
					|последняя в задании на пересчет,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение пересчета товаров?';
					|pl = 'Storage bin ""%1""
					|is the last one in the recount task.
					|No goods are scanned in the storage bin.
					|Do you want to finish the task?';
					|tr = 'Ячейка ""%1"" 
					|последняя в задании на пересчет,
					|и в ней не отсканировано ни одного товара.
					|Завершить выполнение пересчета товаров?'");
			EndIf;
			PresentationOfGoToScanDialogButton = NStr("vi = 'Tiếp tục kiểm đếm hàng hóa';
														|ru = 'Продолжить пересчет товаров';
														|en = 'Resume inventory count'; fa = 'Resume inventory count';
														|it = 'Продолжить пересчет товаров';
														|pl = 'Resume inventory count';
														|tr = 'Stok sayımını devam ettir'");
		EndIf;
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageText,
			?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
		
		Buttons = New ValueList;
		Buttons.Add(NewDialogButton("FinishJobExecution", NStr("vi = 'Kết thúc thực hiện nhiệm vụ';
																|ru = 'Завершить выполнение задания';
																|en = 'Finish task'; fa = 'پایان وظیفه';
																|it = 'Completare task';
																|pl = 'Zakończ wykonanie zadania';
																|tr = 'Görevi tamamla'")));
		Buttons.Add(NewDialogButton("GoToScanning", PresentationOfGoToScanDialogButton));
		
		If JobType = "Move" Then
			If ModeSettings.SelectionScanned Then
				ShowMessageDialog(Form, QueryText, Buttons);
			Else
				WhenCurJobScanIsComplete(Form);
			EndIf;
		Else
			ShowMessageDialog(Form, QueryText, Buttons);
		EndIf;
		
	Else
		
		ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
		
		If Not (JobType = "Filter" 
				Or JobType = "Location")
			Or ThisIsProcessingOrderOfItemCell
			Or Form.GoodsAreSelected Then
			
			GoToTheNextBin(Form);
			Form.GoodsAreSelected = False;
			
		Else
			
			Parameter_1 = "";
			Parameter_2 = "";
			
			MessageText = NStr("vi = 'Không phải tất cả hàng hóa là %1 ""%2"" cho nhiệm vụ hiện tại. %3';
								|ru = 'Не все товары были %1 ""%2"" по текущему заданию. %3';
								|en = 'Task: %1. Not all items are processed in storage bin %2. %3'; fa = 'Task: %1. Not all items are processed in storage bin %2. %3';
								|it = 'Non tutti i prodotti erano %1 ""%2"" secondo il task corrente. %3';
								|pl = 'Nie wszystkie wiersze pozycji zostały %1 ""%2"" dla aktualnego zadania. %3';
								|tr = 'Tüm ürünler %1 ""%2"" mevcut görev için değildir. %3'");
			If JobType = "Filter" Then
				Parameter_1 = NStr("vi = 'được chọn từ ô';
									|ru = 'отобраны из ячейки';
									|en = 'Inv-y picking'; fa = 'Inv-y picking';
									|it = 'selezionati dalla cella';
									|pl = 'wybrane z komórki';
									|tr = 'hücreden seçildi'");
				Parameter_2 = NStr("vi = 'Chọn các mục không được chọn từ các ô khác?';
									|ru = 'Отобрать неотобранные товары из других ячеек?';
									|en = 'Do you want to pick missing items from another storage bin?'; fa = 'Do you want to pick missing items from another storage bin?';
									|it = 'Selezionare i prodotti non selezionati da altre celle?';
									|pl = 'Wybrać nie wybrane wiersze pozycji z innych komórek?';
									|tr = 'Diğer hücrelerden seçili olmayan ürünler seçilsin mi?'");
			Else
				Parameter_1 = NStr("vi = 'xếp vào ô';
									|ru = 'размещены в ячейку';
									|en = 'Inv-y put-away'; fa = 'Inv-y put-away';
									|it = 'collocati nella cella';
									|pl = 'umieszczone w komórce';
									|tr = 'hücreye yerleştirildi'");
				Parameter_2 = NStr("vi = 'Đặt các mục không thay thế trong các ô khác?';
									|ru = 'Разместить неразмещенные товары в других ячейках?';
									|en = 'Do you want to put the rest of the items into another storage bin?'; fa = 'Do you want to put the rest of the items into another storage bin?';
									|it = 'Collocare i prodotti non collocati nelle altre celle?';
									|pl = 'Umieścić nieumieszczone wiersze pozycji w innych komórkach?';
									|tr = 'Yerleştirilmemiş ürünler diğer hücrelere yerleştirilsin mi?'");
			EndIf;
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageText, Parameter_1,
				?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell),
				Parameter_2);
			
			Buttons = New ValueList;
			Buttons.Add(NewDialogButton("SelectGoodsFromOtherBinsWhileTransferringToTheNextBin", NStr("vi = 'Có';
																										|ru = 'Да';
																										|en = 'Yes'; fa = 'بله';
																										|it = 'Sì';
																										|pl = 'Tak';
																										|tr = 'Evet'")));
			Buttons.Add(NewDialogButton("CancelGoodsPickingFromOtherBinsWhileTransferringToTheNextBin",
				NStr("vi = 'Không';
					|ru = 'Нет';
					|en = 'No'; fa = 'خیر';
					|it = 'Non ci sono';
					|pl = 'Nie';
					|tr = 'Hayır'")));
			
			ShowMessageDialog(Form, QueryText, Buttons);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Displays information about the current product in the scan line.
// Called when you click on the product button on the "Scan" page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure DisplayCurProductInformation(Form) Export
	
	If Not Form.ModeSettings.Mode = "Scanning" Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Form.CurrentScanningLine.Products) Then
		Return;
	EndIf;
	
	ProductParameters_1 = New Structure("Products, ItemName, ProductIDOfItems,, ItemsDescription,
		|Characteristic, Package, PackageWeight, PackageVolume");
	FillPropertyValues(ProductParameters_1, Form.CurrentScanningLine);
	
	ProductParameters_ = FindProductByParameters(ProductParameters_1);
	DisplayProductInformation(Form, ProductParameters_);
	
	SetFormHeader(Form, NStr("vi = 'Hàng hóa';
							|ru = 'Товар';
							|en = 'Item'; fa = 'قلم';
							|it = 'Merce';
							|pl = 'Item';
							|tr = 'Ürün'"));
	GoToPage3(Form,"RequestInformationPage");
	
EndProcedure

// Displays information based on the scanned barcode.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** StorageBinLocation - FormField - field for entering the address of the storage cell.
//	Barcode - String - the scanned barcode.
//
Procedure DisplayBarcodeInformation(Form, Barcode) Export
	
	Object = Form.Object;
	WebServiceMode = Form.WebServiceMode;
	
	Form.InformationTable.Clear();
	
	If Not Form.MarkTheBinForRecount Then
		
		// Find the product by barcode.
		PackingListsCanBeUsedInJob = PackingListsCanBeUsedInJob(Form.ModeSettings.JobType);
		FoundProduct = WorkplaceOfWarehouseWorkerApplicationInterface.FindProductOrPackingList(Barcode,
			PackingListsCanBeUsedInJob);
		
		If ValueIsFilled(FoundProduct.Products) Then
			ProductParameters_ = FindProductByParameters(FoundProduct);
			
			DisplayInformationOnProductBarcode(Form, ProductParameters_);
			Return;
		EndIf;
		
		If WebServiceMode Then
			// If it is not a product, then M.B. is a cell.
			CellParameters_ = WorkplaceOfWarehouseWorkerXDTO.CellProductsByBarcode(Form, Barcode);
		Else
			// If it is not a product, then M.B. is a cell.
			CellParameters_ = WorkplaceOfWarehouseWorkerApplicationInterface.FindCellByBarcode(Object.Warehouse,
				Object.Premise, Barcode, True);
		EndIf;
		
		If CellParameters_.ReturnCode = 1 Then
			DisplayInformationOnBarcodeOfCell(Form, CellParameters_.Cell);
			Return;
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось получить информацию по штрихкоду: ""%1"".';
				|vi = 'Cannot receive barcode information: ""%1"".';
				|en = 'Cannot receive barcode information: ""%1"".'; fa = 'Cannot receive barcode information: ""%1"".';
				|it = 'Cannot receive barcode information: ""%1"".';
				|pl = 'Cannot receive barcode information: ""%1"".';
				|tr = 'Barkod bilgisi alınamadı: ""%1"".'"), 
			Barcode);
		
	Else
		
		Form.Items.StorageBinLocation.Enabled = False;
		
		CellParameters_ = WorkplaceOfWarehouseWorkerApplicationInterface.FindCellByBarcode(Object.Warehouse,
			Object.Premise, Barcode, True);
		
		If CellParameters_.ReturnCode = 1 Then
			WorkplaceOfWarehouseWorkerApplicationInterface.MarkABinForRecount(CellParameters_.Cell);
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ô ""%1"" được đánh dấu để tính lại.';
					|ru = 'Ячейка ""%1"" помечена к пересчету.';
					|en = 'Storage bin %1 is marked for physical count.'; fa = 'Storage bin %1 is marked for physical count.';
					|it = 'La cella ""%1"" contrassegnata per il ricalcolo.';
					|pl = 'Komórka ""%1"" oznaczona do przeliczenia.';
					|tr = '""%1"" hücresi yeniden hesaplama için işaretlendi.'"), CellParameters_.Cell);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể đánh dấu ô mã vạch để tính lại: ""%1"".';
					|ru = 'Не удалось отметить к пересчету ячейку по штрихкоду: ""%1"".';
					|en = 'Cannot recognize the barcode: %1. The storage bin is not marked for physical count.'; fa = 'Cannot recognize the barcode: %1. The storage bin is not marked for physical count.';
					|it = 'Non è stato possibile contrassegnare per il ricalcolo la cella con il codice a barre: ""%1"".';
					|pl = 'Nie udało się oznaczyć komórkę do przeliczenia za kodem kreskowym: ""%1"".';
					|tr = 'Hücre yeniden hesaplama için barkodla işaretlenemedi: ''%1''.'"), Barcode);
		EndIf;
		
		Form.BarcodeOfTheScanParameter = "";
		
	EndIf;
	
	GoToPreviousPageButton = NewDialogButton("GoToThePreviousPage", NStr("vi = 'Đồng ý';
																		|ru = 'ОК';
																		|en = 'OK'; fa = 'تأیید';
																		|it = 'OK';
																		|pl = 'OK';
																		|tr = 'Tamam'"), True);
	ShowMessageDialog(Form, MessageText, GoToPreviousPageButton);
	
EndProcedure

// The function returns the structure of the dialog button that is displayed in the user's dialog.
//
// Parameters:
//	CommandName - String - name of the command that will be executed when the button is clicked.
//	Presentation - String - the view button.
//	Select_ - Boolean - if <True>, the label on the button will be made in bold.
//
// Returns:
//	Structure - Dialog Button Parameters:
//	*CommandName - String
//	*Presentation - String
//	*Select_ - Boolean
//
Function NewDialogButton(CommandName, Presentation, Select_ = False) Export
	
	DialogButton = New Structure;
	
	DialogButton.Insert("CommandName", CommandName);
	DialogButton.Insert("Presentation", Presentation);
	DialogButton.Insert("Select_", Select_);
	
	Return DialogButton;
	
EndFunction

// Called from forms when a processing error occurs, the connection of the equipment.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ErrorDescription - String - error description.
//
Procedure IfHardwareConnectionFails(Form, ErrorDescription) Export
	
	// Add an error entry to the log.
	JournalComment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Khi kết nối thiết bị, đã xảy ra lỗi: 
		|""%1"".';
		|ru = 'При подключении оборудования произошла ошибка: 
		|""%1"".';
		|en = 'Equipment connection error:
		|%1.'; fa = 'Equipment connection error:
		|%1.';
		|it = 'Durante il collegamento dell''apparecchiatura si è verificato l''errore: 
		|""%1"".';
		|pl = 'Przy podłączeniu urządzenia wystąpił błąd: 
		|""%1"".';
		|tr = 'Ekipman bağlanırken hata oluştu: 
		|""%1"".'"),
		ErrorDescription);
	
	WriteLogEvent(
		NStr("vi = 'Khi kết nối thiết bị xảy ra lỗi.';
			|ru = 'При подключении оборудования произошла ошибка.';
			|en = 'Equipment connection error.'; fa = 'Equipment connection error.';
			|it = 'Si è verificato un errore durante il collegamento dell''apparecchiatura.';
			|pl = 'Przy podłączeniu urządzenia wystąpił błąd.';
			|tr = 'Ekipman bağlanırken hata oluştu.'",
			Common.DefaultLanguageCode()), 
		EventLogLevel.Error, 
		, 
		, 
		JournalComment, 
		EventLogEntryTransactionMode.Independent);
	
	Form.ModeSettings.YouCanCloseForm = True;
	
	// Output an error message.
	MessageText = NStr("vi = 'Khi kết nối thiết bị đã xảy ra lỗi. 
		|Hãy liên hệ với người quản trị.';
		|ru = 'При подключении оборудования произошла ошибка. 
		|Обратитесь к администратору.';
		|en = 'Equipment connection error.
		|Please contact the administrator.'; fa = 'Equipment connection error.
		|Please contact the administrator.';
		|it = 'Si è verificato un errore durante il collegamento dell''apparecchiatura. 
		| Rivolgetevi all''amministratore.';
		|pl = 'Przy podłączeniu urządzenia wystąpił błąd. 
		|Skontaktuj się z administratorem.';
		|tr = 'Ekipman bağlanırken hata oluştu. 
		|Yöneticiyle iletişime geç.'");
	
	CloseButton = NewDialogButton("CloseTheFormOfMobileWorkplace", NStr("vi = 'Đóng chương trình';
																		|ru = 'Закрыть программу';
																		|en = 'Close application'; fa = 'Close application';
																		|it = 'Chiudere il programma';
																		|pl = 'Zamknij program';
																		|tr = 'Programı kapat'"), True);
	
	ShowMessageDialog(Form, MessageText, CloseButton);
	
EndProcedure

// Called when switching to manual input of the scan value-barcode or
// serial number and expiration date.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** LabelExpirationDateHint - FormField - information label for the user interface.
// 			** LabelBarcodeHint - FormField - information label for the user interface.
//
Procedure ScanEnterAValue(Form) Export
	
	Items = Form.Items;
	WebServiceMode = Form.WebServiceMode;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	ScanParameter = Form.ModeSettings.ScanParameter;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	// Set the initial visibility value of the elements.
	Items.LabelBarcodeHint.Visible = True;
	Items.BarcodeOfTheScanParameter.Visible = True;
	Items.LabelExpirationDateHint.Visible = False;
	Items.SeriesShelfLife.Visible = False;
	
	// Set the hint text.
	If ThisIsSetOfGoods Then
		
		If ScanParameter = "Cell" Then
			BarcodeHint = NStr("vi = 'Hãy nhập tên gọi khu vực nhập hàng (xuất hàng).';
								|ru = 'Введите наименование зоны приемки (отгрузки).';
								|en = 'Enter a warehouse area name.'; fa = 'Enter a warehouse area name.';
								|it = 'Inserite il nome dell''area di accettazione (spedizione).';
								|pl = 'Wpisz nazwę strefy odbioru (wysyłki).';
								|tr = 'Boşaltma (yükleme) alanının adını girin.'");
		ElsIf ScanParameter = "Products" Then
			BarcodeHint = NStr("vi = 'Hãy nhập mã vạch hàng hóa.';
								|ru = 'Введите штрихкод товара.';
								|en = 'Enter a barcode.'; fa = 'Enter a barcode.';
								|it = 'Inserite il codice a barre della merce.';
								|pl = 'Wpisz kod kreskowy towaru.';
								|tr = 'Ürün barkodunu girin.'");
		ElsIf ScanParameter = "Series" Then
			BarcodeHint = NStr("vi = 'Hãy nhập số sê-ri.';
								|ru = 'Введите номер серии.';
								|en = 'Enter a batch number.'; fa = 'Enter a batch number.';
								|it = 'Inserite il numero della serie.';
								|pl = 'Wpisz numer serii.';
								|tr = 'Parti numarasını girin.'");
		EndIf;
		
	Else
		
		If ScanParameter = "Cell" Then
			
			BarcodeHint = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Hãy nhập địa chỉ ô 
					|""%1""';
					|ru = 'Введите адрес ячейки 
					|""%1""';
					|en = 'Enter the address of storage bin:
					|%1'; fa = 'Enter the address of storage bin:
					|%1';
					|it = 'Inserite l''indirizzo della cella 
					|""%1""';
					|pl = 'Wpisz adres komórki 
					|""%1""';
					|tr = 'Hücre adresini girin 
					|""%1""'"), 
				?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
			
		ElsIf ScanParameter = "Products" Then
			
			If JobType = "Recalculate" Then
				BarcodeHint = NStr("vi = 'Hãy nhập mã vạch hàng hóa';
									|ru = 'Введите штрихкод товара';
									|en = 'Enter barcode'; fa = 'Enter barcode';
									|it = 'Inserite il codice a barre della merce';
									|pl = 'Wpisz kod kreskowy towaru';
									|tr = 'Ürün barkodunu girin'");
			Else
				
				If (JobType = "Location" 
						And ThisIsProcessingOrderOfItemCell)
					Or (JobType = "Move"
						And ThisIsProcessingOrderOfItemCell
						And SelectionScanned) Then
					
					BarcodeHint = NStr("vi = 'Hãy nhập mã vạch hàng hóa';
										|ru = 'Введите штрихкод товара';
										|en = 'Enter barcode'; fa = 'Enter barcode';
										|it = 'Inserite il codice a barre della merce';
										|pl = 'Wpisz kod kreskowy towaru';
										|tr = 'Ürün barkodunu girin'");
					
				Else
					
					GoodsPresentation = ?(WebServiceMode,
						GoodsPresentation(
							CurrentScanningLine.ItemName,
							CurrentScanningLine.ItemVariantName,
							CurrentScanningLine.PackageName),
						GoodsPresentation(
							CurrentScanningLine.Products,
							CurrentScanningLine.Characteristic,
							CurrentScanningLine.Package));
					
					BarcodeHint = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Hãy nhập mã vạch hàng hóa 
							|""%1""';
							|ru = 'Введите штрихкод товара 
							|""%1""';
							|en = 'Enter the barcode of item:
							|%1'; fa = 'Enter the barcode of item:
							|%1';
							|it = 'Inserite il codice a barre della merce 
							|""%1""';
							|pl = 'Wpisz kod kreskowy towaru 
							|""%1""';
							|tr = 'Ürün barkodunu girin 
							|""%1""'"), 
						GoodsPresentation);
					
				EndIf;
				
			EndIf;
			
		ElsIf ScanParameter = "Series" Then
			
			BarcodeHint = NStr("vi = 'Hãy nhập số sê-ri';
								|ru = 'Введите номер серии';
								|en = 'Enter batch number'; fa = 'Enter batch number';
								|it = 'Inserite il numero della serie';
								|pl = 'Wpisz numer serii';
								|tr = 'Parti numarasını girin'");
			
			If SeriesIsFilled(JobType, CurrentScanningLine) Then
				
				If JobType = "Move"
					And SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) Then
					
					CurrentScanningLine.BatchName = SetSeriesPresentation(CurrentScanningLine);
					
					BarcodeHint = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Hãy nhập số sê-ri 
							|""%1""';
							|ru = 'Введите номер серии 
							|""%1""';
							|en = 'Enter the number of batch:
							|%1'; fa = 'Enter the number of batch:
							|%1';
							|it = 'Inserite il numero della serie 
							|""%1""';
							|pl = 'Wpisz numer serii 
							|""%1""';
							|tr = 'Parti numarasını girin 
							|""%1""'"), 
						CurrentScanningLine.BatchName);
					
				Else
					
					BarcodeHint = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Hãy nhập số sê-ri 
							|""%1""';
							|ru = 'Введите номер серии 
							|""%1""';
							|en = 'Enter the number of batch:
							|%1'; fa = 'Enter the number of batch:
							|%1';
							|it = 'Inserite il numero della serie 
							|""%1""';
							|pl = 'Wpisz numer serii 
							|""%1""';
							|tr = 'Parti numarasını girin 
							|""%1""'"), 
						?(WebServiceMode, CurrentScanningLine.BatchName, CurrentScanningLine.Series));
					
				EndIf;
				
			EndIf;
			
			If ThisIsSetOfGoods
				Or JobType = "Recalculate"
				Or JobType = "Receiving"
				Or JobType = "PickingCheck" Then
				
				BarcodeHint = NStr("vi = 'Hãy nhập số sê-ri';
									|ru = 'Введите номер серии';
									|en = 'Enter batch number'; fa = 'Enter batch number';
									|it = 'Inserite il numero della serie';
									|pl = 'Wpisz numer serii';
									|tr = 'Parti numarasını girin'");
				
			ElsIf JobType = "Location" Then
				
				If ThisIsProcessingOrderOfItemCell Then
					BarcodeHint = NStr("vi = 'Hãy nhập số sê-ri';
										|ru = 'Введите номер серии';
										|en = 'Enter batch number'; fa = 'Enter batch number';
										|it = 'Inserite il numero della serie';
										|pl = 'Wpisz numer serii';
										|tr = 'Parti numarasını girin'");
				EndIf;
				
			ElsIf JobType = "Move" Then
				
				If SelectionScanned 
					And ThisIsProcessingOrderOfItemCell Then
					
					BarcodeHint = NStr("vi = 'Hãy nhập số sê-ri';
										|ru = 'Введите номер серии';
										|en = 'Enter batch number'; fa = 'Enter batch number';
										|it = 'Inserite il numero della serie';
										|pl = 'Wpisz numer serii';
										|tr = 'Parti numarasını girin'");
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// Set the series input parameters.
	If ScanParameter = "Series" Then
		
		// Depending on the series usage setting, the visibility of the input fields will vary.
		Items.LabelBarcodeHint.Visible = CurrentScanningLine.SpecifyNumberWhenRegisteringBatch;
		Items.BarcodeOfTheScanParameter.Visible = CurrentScanningLine.SpecifyNumberWhenRegisteringBatch;
		Items.LabelExpirationDateHint.Visible = CurrentScanningLine.UseShelfLifeOnBatchRegistration;
		Items.SeriesShelfLife.Visible = CurrentScanningLine.UseShelfLifeOnBatchRegistration;
		
		If Items.SeriesShelfLife.Visible Then
			
			HintOnExpirationDate = NStr("vi = 'Hãy nhập thời hạn sử dụng của sê-ri';
										|ru = 'Введите срок годности серии';
										|en = 'Enter shelf life'; fa = 'Enter shelf life';
										|it = 'Inserite la scadenza della serie';
										|pl = 'Wpisz termin ważności serii';
										|tr = 'Parti son kullanma tarihini gir'");
			
			If SeriesIsFilled(JobType, CurrentScanningLine) Then
				
				If JobType = "Move"
					And SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) Then
					
					CurrentScanningLine.BatchName = SetSeriesPresentation(CurrentScanningLine);
					
					HintOnExpirationDate = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Hãy nhập thời hạn sử dụng sê-ri 
							|""%1""';
							|ru = 'Введите срок годности серии 
							|""%1""';
							|en = 'Enter shelf life for batch:
							|%1'; fa = 'Enter shelf life for batch:
							|%1';
							|it = 'Inserite la scadenza della serie 
							|""%1""';
							|pl = 'Wpisz termin ważności serii 
							|""%1""';
							|tr = 'Parti son kullanma tarihini girin 
							|""%1""'"), 
						CurrentScanningLine.BatchName);
					
				Else
					
					HintOnExpirationDate = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Hãy nhập thời hạn sử dụng sê-ri 
								|""%1""';
								|ru = 'Введите срок годности серии 
								|""%1""';
								|en = 'Enter shelf life for batch:
								|%1'; fa = 'Enter shelf life for batch:
								|%1';
								|it = 'Inserite la scadenza della serie 
								|""%1""';
								|pl = 'Wpisz termin ważności serii 
								|""%1""';
								|tr = 'Parti son kullanma tarihini girin 
								|""%1""'"), 
						?(WebServiceMode, CurrentScanningLine.BatchName, CurrentScanningLine.Series));
					
				EndIf;
				
			EndIf;
			
			If ThisIsSetOfGoods 
				Or JobType = "Recalculate"
				Or JobType = "Receiving"
				Or JobType = "PickingCheck" Then
				
				HintOnExpirationDate = NStr("vi = 'Hãy nhập thời hạn sử dụng của sê-ri';
											|ru = 'Введите срок годности серии';
											|en = 'Enter shelf life'; fa = 'Enter shelf life';
											|it = 'Inserite la scadenza della serie';
											|pl = 'Wpisz termin ważności serii';
											|tr = 'Parti son kullanma tarihini gir'");
				
			ElsIf JobType = "Location" Then
				
				If ThisIsProcessingOrderOfItemCell Then
					HintOnExpirationDate = NStr("vi = 'Hãy nhập thời hạn sử dụng của sê-ri';
												|ru = 'Введите срок годности серии';
												|en = 'Enter shelf life'; fa = 'Enter shelf life';
												|it = 'Inserite la scadenza della serie';
												|pl = 'Wpisz termin ważności serii';
												|tr = 'Parti son kullanma tarihini gir'");
				EndIf;
				
			ElsIf JobType = "Move" Then
				
				If SelectionScanned 
					And ThisIsProcessingOrderOfItemCell Then
					
					HintOnExpirationDate = NStr("vi = 'Hãy nhập thời hạn sử dụng của sê-ri';
												|ru = 'Введите срок годности серии';
												|en = 'Enter shelf life'; fa = 'Enter shelf life';
												|it = 'Inserite la scadenza della serie';
												|pl = 'Wpisz termin ważności serii';
												|tr = 'Parti son kullanma tarihini gir'");
					
				EndIf;
				
			EndIf;
			
			Items.LabelExpirationDateHint.Title = HintOnExpirationDate;
			
		EndIf;
		
	EndIf;
	
	Items.LabelBarcodeHint.Title = BarcodeHint;
	
	Form.CurrentItem = Items.BarcodeOfTheScanParameter;
	GoToPage3(Form, "SelectValuePage");
	
EndProcedure

// The procedure sets the form title text and centers it.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	TitleText - String - text of the form title.
//
Procedure SetFormHeader(Form, TitleText) Export
	
	Form.Title = TitleText;
	CenterFormHeaderText(Form);
	
EndProcedure

// Sets the title text of the list of warehouse tasks.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	DocumentsCount - Number - number of documents.
//
Procedure SetTaskListTitle(Form, DocumentsCount) Export
	
	JobType = Form.ModeSettings.JobType;
	
	FormTitleText = "";
	
	If JobType = "Filter" Then
		
		FormTitleText = ?(Form.DisplayAllJobs, 
			CaptionTextOfFormElementTitle("TitleAllSelectionTasks", Form), 
			CaptionTextOfFormElementTitle("TitleMySelectionTasks", Form));
		
	ElsIf JobType = "Location" Then
		
		FormTitleText = ?(Form.DisplayAllJobs, 
			CaptionTextOfFormElementTitle("TitleAllPlacementTasks", Form), 
			CaptionTextOfFormElementTitle("TitleMyPlacementTasks", Form));
		
	ElsIf JobType = "Move" Then
		
		FormTitleText = ?(Form.DisplayAllJobs, 
			CaptionTextOfFormElementTitle("TitleAllMovingTasks", Form), 
			CaptionTextOfFormElementTitle("HeadingMyMovingTasks", Form));
		
	ElsIf JobType = "Recalculate" Then
		
		FormTitleText = ?(Form.DisplayAllJobs, 
			CaptionTextOfFormElementTitle("TitleAllRecalculationTasks", Form), 
			CaptionTextOfFormElementTitle("TitleMyRecalculationTasks", Form));
		
	ElsIf JobType = "Receiving" Then
		
		FormTitleText = ?(Form.DisplayAllJobs, 
			CaptionTextOfFormElementTitle("TitleAllTasksForAcceptance", Form), 
			CaptionTextOfFormElementTitle("TitleMyAcceptanceTasks", Form));
		
	ElsIf JobType = "PickingCheck" Then
		
		FormTitleText = ?(Form.DisplayAllJobs, 
			CaptionTextOfFormElementTitle("TitleAllTasksForReview", Form), 
			CaptionTextOfFormElementTitle("TitleMyVerificationTasks", Form));
		
	EndIf;
	
	FormTitleText = FormTitleText + " (" + DocumentsCount + ")";
	
	SetFormHeader(Form, FormTitleText);
	
EndProcedure

// Sets captions for labels and commands for managing the order 
// in which product series are scanned.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetParametersOfScanSchemeElements(Form) Export
	
	SeriesScanMode = Form.SeriesScanMode;
	
	If SeriesScanMode = "" Then
		SeriesScanMode = "ProductSeriesProduct"
	EndIf; 
	
	If SeriesScanMode = "ProductSeriesProduct" Then
		SetButtonDisplayParameters(Form, "ServiceTSTSeriesScanMode", "Clicked");
		SetButtonDisplayParameters(Form, "ServiceTBTSeriesScanMode", "NotClicked");
	ElsIf SeriesScanMode = "ProductAllSeries" Then
		SetButtonDisplayParameters(Form, "ServiceTBTSeriesScanMode", "Clicked");
		SetButtonDisplayParameters(Form, "ServiceTSTSeriesScanMode", "NotClicked");
	EndIf;
	
EndProcedure

// Called when you click the "product Series" button on the workplace form.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ServiceTBTSeriesScanMode(Form) Export
	
	If Form.SeriesScanMode = "ProductAllSeries" Then
		Return;
	EndIf;
	
	WhenInstallingProductScanScheme(Form);
	
EndProcedure

// Called when pressing "Courseresources" on the form of the workplace.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ServiceTSTSeriesScanMode(Form) Export
	
	If Form.SeriesScanMode = "ProductSeriesProduct" Then
		Return;
	EndIf;
	
	WhenInstallingProductScanScheme(Form);
	
EndProcedure

// Called when the product scanning scheme changes from the service page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure WhenInstallingProductScanScheme(Form) Export
	
	ScanParameter = Form.ModeSettings.ScanParameter;
	SeriesScanMode = Form.SeriesScanMode;
	
	If SeriesScanMode = "ProductAllSeries" Then
		If ScanParameter = "Series" Then
			SetParameterScanFlag(Form, "Products", True);
			GoToNextScanOption(Form);
			SetParametersForScanItems(Form);
		EndIf;
	EndIf;
	
	Form.SeriesScanMode = ?(SeriesScanMode = "ProductSeriesProduct", "ProductAllSeries", "ProductSeriesProduct");
	SetParametersOfScanSchemeElements(Form);
	
EndProcedure

// Called when the Cell-Item processing order is set.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure WhenSettingProcessingOrderItemCell(Form) Export
	
	ProcessingProcedure_ = Form.ModeSettings.ProcessingProcedure_;
	
	If ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.StorageBinGoods Then
		Return;
	EndIf;
	
	Form.ModeSettings.ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.StorageBinGoods;
	
	SetAvailabilityOfScanSchemeChange(Form);
	SetParametersForItemsInWarehouseTaskProcessingOrder(Form);
	SetHotkeysOnCurPage(Form);
	CreateQueueOfScanParameters(Form);
	GoToNearestNonScannedProductLine(Form);
	ResetSignsOfScanningAllParameters(Form);
	SetParameterScanFlag(Form, "Cell", True);
	GoToNextScanOption(Form);
	SetVisibilityOfQuantityInDocument(Form);
	
EndProcedure

// Called when the Item-Cell processing order is set.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure WhenSettingOrderOfProcessingItemCell(Form) Export
	
	ProcessingProcedure_ = Form.ModeSettings.ProcessingProcedure_;
	If ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.GoodsBin Then
		Return;
	EndIf;
	
	Form.ModeSettings.ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.GoodsBin;
	
	ServiceTSTSeriesScanMode(Form);
	
	SetAvailabilityOfScanSchemeChange(Form);
	SetParametersForItemsInWarehouseTaskProcessingOrder(Form);
	SetHotkeysOnCurPage(Form);
	CreateQueueOfScanParameters(Form);
	
	Form.CurrentScanningLine = ScanLine();
	
	GoToNextScanOption(Form);
	SetVisibilityOfQuantityInDocument(Form);
	
EndProcedure

// Called when you click the "Tools" button on the "Scan" page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ScanningService(Form) Export
	
	SetAvailabilityOfScanSchemeChange(Form);
	SetVisibilityToChangeCrawlOrder(Form);
	
	GoToPage3(Form,"PageService");
	
EndProcedure

// Called when you press the buttons to return to scan mode.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ContinueScanningService(Form) Export
	
	GoToPage3(Form,"ScanPage");
	
EndProcedure

// Invoked when buttons are pressed return to complete the task.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ReturnToTheJob(Form) Export
	
	GoToPage3(Form,"ScanPage");
	
EndProcedure

// Wait handler for the " OK " command on the barcode value input page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SelectingOKValueWaitHandler(Form) Export
	
	If Not Form.EnteringBarcodeIsCanceled Then
		
		GoToPage3(Form,"ScanPage");
		
		Form.ModeSettings.Mode = "EnterValue";
		WhenScanningValue(Form, Form.BarcodeOfTheScanParameter, Form.SeriesShelfLife);
		
	EndIf;
	
EndProcedure

// The procedure displays the status of the warehouse task execution. Depending on 
// the type of task being performed, either a progress bar is displayed, or a row shows the number
// of scanned products and cells.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure DisplayTaskState(Form) Export
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ScannedGoods = Form.ScannedGoods;
	CellsForScanning = Form.CellsForScanning;
	GoodsForScanning = Form.GoodsForScanning;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	StateInformationText = "";
	JobExecutionState = 0;
	
	If Items.FormPages.CurrentPage <> Items.ScanPage Then
		Return;
	EndIf;
	
	NumberOfTareLines = NumberOfRowsOfScannedContainers(Form);
	
	If ThisIsSetOfGoods Then
		
		Filter = New Structure("NumberOfPackagingsScanned", 0);
		RowsArray = ScannedGoods.FindRows(Filter);
		
		NumberOfScannedLines = ScannedGoods.Count() - RowsArray.Count() + NumberOfTareLines;
		
		If NumberOfScannedLines = 0 Then
			StateInformationText = "";
		ElsIf Form.UsePackingLists
			And JobType = "Receiving" Then
			
			StateInformationText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 %2';
																								|ru = '%1 %2';
																								|en = '%1 %2'; fa = '%1 %2';
																								|it = '%1 %2';
																								|pl = '%1 %2';
																								|tr = '%1 %2'"),
				?(NumberOfScannedLines > 1, NStr("vi = 'Đã thêm';
												|ru = 'Добавлено';
												|en = 'Added'; fa = 'اضافه‌شده';
												|it = 'Aggiunto';
												|pl = 'Dodano';
												|tr = 'Eklendi'"), NStr("vi = 'Đã thêm';
																		|ru = 'Добавлено';
																		|en = 'Added'; fa = 'اضافه‌شده';
																		|it = 'Aggiunto';
																		|pl = 'Dodano';
																		|tr = 'Eklendi'")),
				StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(NumberOfScannedLines, "position, positions, positions_2"));
			
		Else
			StateInformationText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 %2';
																								|ru = '%1 %2';
																								|en = '%1 %2'; fa = '%1 %2';
																								|it = '%1 %2';
																								|pl = '%1 %2';
																								|tr = '%1 %2'"),
				?(NumberOfScannedLines > 1, NStr("vi = 'Đã thêm';
												|ru = 'Добавлено';
												|en = 'Added'; fa = 'اضافه‌شده';
												|it = 'Aggiunto';
												|pl = 'Dodano';
												|tr = 'Eklendi'"), NStr("vi = 'Đã thêm';
																		|ru = 'Добавлено';
																		|en = 'Added'; fa = 'اضافه‌شده';
																		|it = 'Aggiunto';
																		|pl = 'Dodano';
																		|tr = 'Eklendi'")), 
				StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(NumberOfScannedLines, "owngoods, ofproduct, ofproducts_"));
			
		EndIf;
		
	ElsIf JobType = "Recalculate" Then
		
		NumberOfScannedCells = 0;
		If ValueIsFilled(CurrentScanningLine.SKCell) Then
			NumberOfScannedCells = 1;
		EndIf;
		
		JobExecutionState = CellsForScanning.Total("Scanned") + NumberOfScannedCells;
		
	ElsIf JobType = "PickingCheck" Then
		JobExecutionState = ScannedGoods.Total("NumberOfPackagingsScanned") 
			- ScannedGoods.Total("NumberOfPackagesDoNotShip");
	Else
		JobExecutionState = GoodsForScanning.Total("NumberOfPackagingsScanned");
	EndIf;
	
	// Set the desired status display page.
	If ThisIsSetOfGoods Then
		Items.PagesStateErrorText.CurrentPage = Items.PageStateAsAString;
	Else
		Items.PagesStateErrorText.CurrentPage = Items.PageState;
	EndIf;
	
	Form.StateInformationText = StateInformationText;
	Form.JobExecutionState = JobExecutionState;
	
EndProcedure

// Called when you select a line in the list of available warehouse zones - acceptance or shipment.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** ReceivingShippingAreas - FormTable - a table containing information about the warehouse's acceptance zones and shipments.
//
Procedure WhenSelectingShipmentAcceptanceZone(Form) Export
	
	CurrentRowNumber = Form.Items.ReceivingShippingAreas.CurrentRow;
	Cell = Form.ReceivingShippingAreas.FindByID(CurrentRowNumber);
	
	ModeSettings = Form.ModeSettings;
	SelectionOfShipmentAcceptanceZone = ModeSettings.SelectionOfShipmentAcceptanceZone;
	
	If Cell = Undefined Then
		ReturnToTheJob(Form);
		Return;
	EndIf;
	
	If SelectionOfShipmentAcceptanceZone = "ReceivingArea" Then
		ModeSettings.ReceivingArea = Cell.Cell;
		ModeSettings.NameOfAcceptanceZone = Cell.CellCode;
	ElsIf SelectionOfShipmentAcceptanceZone = "ShippingZone" Then
		ModeSettings.ShippingZone = Cell.Cell;
		ModeSettings.NameOfShippingArea = Cell.CellCode;
	EndIf;
	
	CompleteWarehouseTask(Form);
	
EndProcedure

// Called when a destination is selected
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** Assignments - FormTable - a table containing information about the purpose of goods for separate storage.
//
Procedure WhenSelectingDestination(Form) Export
	
	IDOfCurLine = Form.Items.Assignments.CurrentRow;
	If IDOfCurLine = Undefined Then
		Return;
	EndIf;
	Form.CurrentScanningLine.NewAssignment = Form.Object.Assignments.FindByID(IDOfCurLine).Purpose;
	If Form.CurrentScanningLine.NewAssignment = Form.CurrentScanningLine.Purpose Then
		GoToPage3(Form,"ScanPage");
	ElsIf SeriesAreSpecifiedForReference(Form.CurrentScanningLine.BatchesIndicationStatus)
		And SeriesIdentifiesItemInstance(Form.CurrentScanningLine) Then
		
		Form.EnterTheNumberOfTheNumber = Form.CurrentScanningLine.NumberOfPackagingsScanned;
		Form.ModeSettings.Mode    = "EnteringQuantityAsIntended";
		
		EnterQuantity(Form);
		
	Else
		Form.EnterTheNumberOfTheNumber = Form.CurrentScanningLine.NumberOfPackagingsScanned;
		
		If Not ThisIsTara(Form.CurrentScanningLine)
			And Form.CurrentScanningLine.PackageWeight <> 0 Then
			
			Form.EnterQuantityWeight = Form.EnterTheNumberOfTheNumber * Form.CurrentScanningLine.PackageWeight
				/ Form.CurrentScanningLine.FactorOfWeightUnitOfMeasure;
			
		EndIf;
		
		If Not ThisIsTara(Form.CurrentScanningLine)
			And Form.CurrentScanningLine.PackageVolume <> 0 Then
			
			Form.EnterQuantityVolume = Form.EnterTheNumberOfTheNumber * Form.CurrentScanningLine.PackageVolume
				/ Form.CurrentScanningLine.FactorOfVolumeUnitOfMeasure;
			
		EndIf;
		
		Form.ModeSettings.Mode = "EnteringQuantityAsIntended";
		GoToPage3(Form,"EnterQuantityPage");
		
	EndIf;
	
EndProcedure

// Called when you click the Quantity button on the Scan page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ScanToEnterTheNumber(Form) Export
	
	ModeSettings = Form.ModeSettings;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsPlacementAssignment = (ModeSettings.JobType = "Location");
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(ModeSettings.ProcessingProcedure_);
	
	If Not (CurrentScanningLine = Undefined) Then
		
		If ThisIsPlacementAssignment 
			And ThisIsProcessingOrderOfItemCell Then
			
			Form.EnterTheNumberOfTheNumber = CurrentScanningLine.NumberOfPackagesToPut;
			
		Else
			Form.EnterTheNumberOfTheNumber = CurrentScanningLine.NumberOfPackagingsScanned;
		EndIf;
		
		If Not ThisIsTara(CurrentScanningLine)
			And CurrentScanningLine.PackageWeight <> 0 Then
			
			Form.EnterQuantityWeight = Form.EnterTheNumberOfTheNumber * CurrentScanningLine.PackageWeight
				/ CurrentScanningLine.FactorOfWeightUnitOfMeasure;
			
		EndIf;
		
		If Not ThisIsTara(CurrentScanningLine)
			And CurrentScanningLine.PackageVolume <> 0 Then
			
			Form.EnterQuantityVolume = Form.EnterTheNumberOfTheNumber * CurrentScanningLine.PackageVolume
				/ CurrentScanningLine.FactorOfVolumeUnitOfMeasure;
			
		EndIf;
		
	EndIf;
	
	If Form.ModeSettings.ScanParameter = "Series" Then
		Form.TheCurrentSeriesScanParameter = True;
	EndIf;
	
	ModeSettings.Mode = "EnterQuantity";
	
	GoToPage3(Form, "EnterQuantityPage");
	
EndProcedure

// The waiting handler for entering a quantity is called when you go to the quantity input page.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the warehouse employee's workplace form.
//
Procedure EnteringNumberOfOKWaitHandler(Form) Export
	
	If Not Form.EnteringQuantityIsCanceled Then
		EnterQuantity(Form);
	EndIf;
	If Not (Form.Items.FormPages.CurrentPage = Form.Items.ScanPage)
		And (Form.Items.FormPages.CurrentPage = Form.Items.EnterQuantityPage) Then // They could have already completed the task and moved to another page
		GoToPage3(Form, "ScanPage");
	EndIf;
	
EndProcedure

// Called when you click the Cancel button on the quantity input page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure EnteringAQuantityCancel(Form) Export
	
	Form.EnteringQuantityIsCanceled = True;
	
	Form.EnterQuantityWeight = 0;
	Form.EnterQuantityVolume = 0;
	Form.EnterTheNumberOfTheNumber = 0;
	
	GoToPage3(Form,"ScanPage");
	
EndProcedure

// Called when you click the "Do not ship" button on the "Scan" page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ScanNotShip(Form) Export
	
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If Not (CurrentScanningLine = Undefined) Then
		
		Form.EnterTheNumberOfTheNumber = CurrentScanningLine.NumberOfPackagesDoNotShip;
		
		If Not ThisIsTara(CurrentScanningLine)
			And CurrentScanningLine.PackageWeight <> 0 Then
			
			Form.EnterQuantityWeight = Form.EnterTheNumberOfTheNumber * CurrentScanningLine.PackageWeight
				/ CurrentScanningLine.FactorOfWeightUnitOfMeasure;
			
		EndIf;
		
		If Not ThisIsTara(CurrentScanningLine)
			And CurrentScanningLine.PackageVolume <> 0 Then
			
			Form.EnterQuantityVolume = Form.EnterTheNumberOfTheNumber * CurrentScanningLine.PackageVolume
				/ CurrentScanningLine.FactorOfVolumeUnitOfMeasure;
			
		EndIf;
		
	EndIf;
	
	If Form.ModeSettings.ScanParameter = "Series" Then
		Form.TheCurrentSeriesScanParameter = True;
	EndIf;
	
	Form.ModeSettings.Mode = "EnteringQuantityNotToShip";
	
	GoToPage3(Form,"EnterQuantityPage");
	
EndProcedure

// Returns a reference to the string table in the navigation history through the pages of the form.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	FormDataCollectionItem - a row in the transition history table.
//
Function PreviousPage(Form) Export
	
	If Form.TransfersByPages.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	If Form.TransfersByPages.Count() = 1 Then
		PreviousPage = Form.TransfersByPages[0];
	Else
		If Form.MarkTheBinForRecount 
			And Form.ModeSettings.Mode = "ActionChoice" Then
			
			PreviousPage = Form.TransfersByPages[Form.TransfersByPages.Count() - 3];
			
		Else
			PreviousPage = Form.TransfersByPages[Form.TransfersByPages.Count() - 2];
		EndIf;
	EndIf;
	
	Form.MarkTheBinForRecount = False;
	
	Return PreviousPage;
	
EndFunction

// Navigates to the previous page. The previous page is taken from the click history.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToThePreviousPage(Form) Export
	
	PreviousPage = PreviousPage(Form);
	SetFormHeader(Form,PreviousPage.PageHeader);
	
	If PreviousPage.PageName = "ScanPage" Then
		DisplayTaskState(Form);
	EndIf;
	
	GoToPage3(Form, PreviousPage.PageName);
	
EndProcedure

// Called when selecting a warehouse task from the list, or when clicking the "Select" button.
// Look into the Processing.The worker of the employee's salary.Forms.FormaRabochehOmest*.
// 
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** Jobs - FormTable - a table containing information about warehouse tasks.
// 		* Jobs - FormDataCollection - a table containing information about warehouse tasks, which contains:
// 			** Ref - DocumentRef.GoodsReceiptNote, DocumentRef.GoodsIssueNote, DocumentRef.GoodsPickingPlacement, DocumentRef.InventoryRecount - a warehouse task that is being accepted for work.
//
Procedure WhenSelectingTask(Form) Export
	
	CurrentRowNumber = Form.Items.Jobs.CurrentRow;
	If CurrentRowNumber = Undefined Then
		Return;
	EndIf;
	
	JobRow = Form.Jobs.FindByID(CurrentRowNumber);
	Job = JobRow.Ref;
	
	TakeTaskToWork(Form, Job);
	
EndProcedure

// Displays a dialog message with a list of buttons. The message text and command structure
// are formed dynamically depending on the type of the current warehouse task and 
// its status.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ScanningAnAction(Form) Export
	
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	Buttons = New ValueList;
	
	FinishButton  = NewDialogButton("FinishJobExecution", NStr("vi = 'Kết thúc thực hiện nhiệm vụ';
																|ru = 'Завершить выполнение задания';
																|en = 'Finish task'; fa = 'پایان وظیفه';
																|it = 'Completare task';
																|pl = 'Zakończ wykonanie zadania';
																|tr = 'Görevi tamamla'"));
	CancelButton_2 = NewDialogButton("CancelJobExecution", NStr("vi = 'Hủy thực hiện nhiệm vụ';
																|ru = 'Отменить выполнение задания';
																|en = 'Cancel task'; fa = 'لغو وظیفه';
																|it = 'Annulla completamento task';
																|pl = 'Anuluj wykonanie zadania';
																|tr = 'Görevin gerçekleştirilmesini iptal et'"));
	
	If ThisIsSetOfGoods Then
		
		If JobType = "Location" Then
			
			QueryText = NStr("vi = 'Hủy bỏ 
			|thêm hàng hóa 
			|vào nhiệm vụ xếp vào?';
			|ru = 'Отменить 
			|добавление товаров 
			|в задание на размещение?';
			|en = 'Undo
			|adding items
			|to the Put-away task?'; fa = 'Undo
			|adding items
			|to the Put-away task?';
			|it = 'Annullare 
			| l''aggiunta delle merci 
			| nel task per il collocamento?';
			|pl = 'Anulować 
			|dodawanie towarów
			|w zadanie na umieszczenie?';
			|tr = 'Yerleştirme görevine 
			|ürün eklemeyi 
			|iptal et?'");
			
			BackToExecutionButton = NewDialogButton(
				"GoToThePreviousPage", 
				NStr("vi = 'Quay lại 
				|thực hiện nhiệm vụ';
				|ru = 'Вернуться 
				|к выполнению задания';
				|en = 'Resume
				|task'; fa = 'Resume
				|task';
				|it = 'Tornare 
				| all''esecuzione del task';
				|pl = 'Powrót 
				|do wykonania zadania';
				|tr = 'Görevin 
				|gerçekleştirilmesine geri dön'"), 
				True);
			
			Buttons.Add(BackToExecutionButton);
			Buttons.Add(CancelButton_2);
			
		ElsIf JobType = "Receiving" Then
			
			QueryText = NStr("vi = 'Hủy nhập hàng?';
							|ru = 'Отменить приемку товаров?';
							|en = 'Cancel goods receipt?'; fa = 'Cancel goods receipt?';
							|it = 'Annullare l''accettazione delle merci?';
							|pl = 'Anulować odbiór towarów?';
							|tr = 'Mal girişini iptal et?'");
			
			BackToExecutionButton = NewDialogButton(
				"ReturnToTheJob", 
				NStr("vi = 'Quay lại 
				|thực hiện nhiệm vụ';
				|ru = 'Вернуться 
				|к выполнению задания';
				|en = 'Resume
				|task'; fa = 'Resume
				|task';
				|it = 'Tornare 
				| all''esecuzione del task';
				|pl = 'Powrót 
				|do wykonania zadania';
				|tr = 'Görevin 
				|gerçekleştirilmesine geri dön'"), 
				True);
			
			Buttons.Add(BackToExecutionButton);
			Buttons.Add(CancelButton_2);
			
		EndIf;
		
	Else
		
		If JobType = "Recalculate" Then
			
			ContinueButton = NewDialogButton(
				"GoToThePreviousPage", 
				NStr("vi = 'Tiếp tục 
				|kiểm đếm hàng hóa';
				|ru = 'Продолжить 
				|пересчет товаров';
				|en = 'Resume
				|inventory count'; fa = 'Resume
				|inventory count';
				|it = 'Continuare 
				| il ricalcolo delle merci';
				|pl = 'Kontynuować 
				|przeliczanie towarów';
				|tr = 'Ürünleri 
				|saymaya devam et'"), True);
			
			FinishButton = NewDialogButton(
				"FinishJobExecution", 
				NStr("vi = 'Kết thúc 
				|kiểm đếm hàng hóa';
				|ru = 'Завершить 
				|пересчет товаров';
				|en = 'Finish
				|inventory count'; fa = 'Finish
				|inventory count';
				|it = 'Terminare 
				| il ricalcolo delle merci';
				|pl = 'Zakończyć 
				|przeliczanie towarów';
				|tr = 'Ürünleri 
				|saymayı tamamla'"));
			
			CancelButton_2 = NewDialogButton(
				"CancelJobExecution", 
				NStr("vi = 'Hủy bỏ 
				|kiểm đếm hàng hóa';
				|ru = 'Отменить 
				|пересчет товаров';
				|en = 'Cancel
				|inventory count'; fa = 'Cancel
				|inventory count';
				|it = 'Annullare 
				|il ricalcolo delle merci';
				|pl = 'Anulować 
				|przeliczanie towarów';
				|tr = 'Ürünleri 
				|saymayı iptal et'"));
			
			Buttons.Add(ContinueButton);
			
			If ThereAreScannedProducts(Form) Then
				QueryText = NStr("vi = 'Kết thúc
				|kiểm đếm hàng hóa?';
				|ru = 'Завершить
				|пересчет товаров?';
				|en = 'Finish
				|inventory count?'; fa = 'Finish
				|inventory count?';
				|it = 'Terminare 
				|il ricalcolo delle merci?';
				|pl = 'Zakończyć 
				|przeliczanie towarów?';
				|tr = 'Ürünleri
				|saymayı tamamla?'");
				Buttons.Add(FinishButton);
			Else
				QueryText = NStr("vi = 'Hủy bỏ
				|kiểm đếm hàng hóa?';
				|ru = 'Отменить
				|пересчет товаров?';
				|en = 'Cancel
				|inventory count?'; fa = 'Cancel
				|inventory count?';
				|it = 'Annullare 
				|il ricalcolo delle merci?';
				|pl = 'Anulować
				|przeliczanie towarów?';
				|tr = 'Ürünleri
				|saymayı iptal et?'");
				Buttons.Add(CancelButton_2);
			EndIf;
			
		ElsIf JobType = "Filter" Then
			
			ContinueButton = NewDialogButton(
				"GoToThePreviousPage", 
				NStr("vi = 'Tiếp tục 
				|lấy ra hàng hóa';
				|ru = 'Продолжить 
				|отбор товаров';
				|en = 'Resume
				|picking job'; fa = 'Resume
				|picking job';
				|it = 'Continuare 
				| la selezione delle merci';
				|pl = 'Kontynuować 
				|wybór towarów';
				|tr = 'Ürünleri 
				|filtrelemeye devam et'"));
			
			FinishButton = NewDialogButton(
				"FinishJobExecution", 
				NStr("vi = 'Kết thúc 
				|lấy ra hàng hóa';
				|ru = 'Завершить 
				|отбор товаров';
				|en = 'Finish
				|picking job'; fa = 'Finish
				|picking job';
				|it = 'Terminare 
				| la selezione delle merci';
				|pl = 'Zakończyć 
				|wybór towarów';
				|tr = 'Ürünleri 
				|filtrelemeyi tamamla'"));
				
			CancelButton_2 = NewDialogButton(
				"CancelJobExecution", 
				NStr("vi = 'Hủy bỏ 
				|lấy ra hàng hóa';
				|ru = 'Отменить 
				|отбор товаров';
				|en = 'Cancel
				|picking job'; fa = 'Cancel
				|picking job';
				|it = 'Annullare 
				| la selezione delle merci';
				|pl = 'Anulować 
				|wybór towarów';
				|tr = 'Ürünleri 
				|filtrelemeyi iptal et'"));
			
			Buttons.Add(ContinueButton);
			
			If ThereAreScannedProducts(Form) Then
				QueryText = NStr("vi = 'Kết thúc 
				|lấy ra hàng hóa?';
				|ru = 'Завершить 
				|отбор товаров?';
				|en = 'Finish
				|picking job?'; fa = 'Finish
				|picking job?';
				|it = 'Terminare 
				| la selezione delle merci?';
				|pl = 'Zakończyć 
				|wybór towarów?';
				|tr = 'Ürünleri 
				|filtrelemeyi tamamla?'");
				Buttons.Add(FinishButton);
			Else
				QueryText = NStr("vi = 'Hủy bỏ 
				|lấy ra hàng hóa?';
				|ru = 'Отменить 
				|отбор товаров?';
				|en = 'Cancel
				|picking job?'; fa = 'Cancel
				|picking job?';
				|it = 'Annullare 
				| la selezione delle merci?';
				|pl = 'Anulować 
				|wybór towarów?';
				|tr = 'Ürünleri 
				|filtrelemeyi iptal et?'");
				Buttons.Add(CancelButton_2);
			EndIf;
			
		ElsIf JobType = "Location" Then
			
			ContinueButton = NewDialogButton(
				"GoToThePreviousPage", 
				NStr("vi = 'Tiếp tục 
				|xếp vào hàng hóa';
				|ru = 'Продолжить 
				|размещение товаров';
				|en = 'Resume
				|put-away task'; fa = 'Resume
				|put-away task';
				|it = 'Continuare 
				| il collocamento delle merci';
				|pl = 'Kontynuować 
				|umieszczenie towarów';
				|tr = 'Ürün 
				|yerleştirmeye devam et'"));
			
			FinishButton = NewDialogButton(
				"FinishJobExecution", 
				NStr("vi = 'Kết thúc 
				|xếp vào hàng hóa';
				|ru = 'Завершить 
				|размещение товаров';
				|en = 'Finish
				|put-away task'; fa = 'Finish
				|put-away task';
				|it = 'Terminare 
				| il collocamento delle merci';
				|pl = 'Zakończyć  
				|umieszczenie towarów';
				|tr = 'Ürün 
				|yerleştirmeyi tamamla'"));
				
			CancelButton_2 = NewDialogButton(
				"CancelJobExecution", 
				NStr("vi = 'Hủy bỏ 
				|xếp vào hàng hóa';
				|ru = 'Отменить 
				|размещение товаров';
				|en = 'Cancel
				|put-away task'; fa = 'Cancel
				|put-away task';
				|it = 'Annullare 
				| il collocamento delle merci';
				|pl = 'Anulować 
				|umieszczenie towarów';
				|tr = 'Ürün 
				|yerleştirmeyi iptal et'"));
			
			Buttons.Add(ContinueButton);
			
			If ThereAreScannedProducts(Form) Then
				QueryText = NStr("vi = 'Kết thúc 
				|xếp vào hàng hóa?';
				|ru = 'Завершить 
				|размещение товаров?';
				|en = 'Finish
				|put-away task?'; fa = 'Finish
				|put-away task?';
				|it = 'Terminare 
				| il collocamento delle merci?';
				|pl = 'Zakończyć  
				|umieszczenie towarów?';
				|tr = 'Ürün 
				|yerleştirmeyi tamamla?'");
				Buttons.Add(FinishButton);
			Else
				QueryText = NStr("vi = 'Hủy bỏ 
				|xếp vào hàng hóa?';
				|ru = 'Отменить 
				|размещение товаров?';
				|en = 'Cancel
				|put-away task?'; fa = 'Cancel
				|put-away task?';
				|it = 'Annullare 
				| il collocamento delle merci?';
				|pl = 'Anulować 
				|umieszczenie towarów?';
				|tr = 'Ürün 
				|yerleştirmeyi iptal et?'");
				Buttons.Add(CancelButton_2);
			EndIf;
			
		ElsIf JobType = "Move" Then
			
			ContinueButton = NewDialogButton(
				"GoToThePreviousPage", 
				NStr("vi = 'Tiếp tục 
				|điều chuyển hàng hóa';
				|ru = 'Продолжить 
				|перемещение товаров';
				|en = 'Resume
				|transfer task'; fa = 'Resume
				|transfer task';
				|it = 'Continuare 
				| lo spostamento delle merci';
				|pl = 'Kontynuować 
				|przenoszenie towarów';
				|tr = 'Mal 
				|transferine devam et'"), True);
			
			FinishButton = NewDialogButton(
				"FinishJobExecution", 
				NStr("vi = 'Kết thúc 
				|điều chuyển hàng hóa';
				|ru = 'Завершить 
				|перемещение товаров';
				|en = 'Finish
				|transfer task'; fa = 'Finish
				|transfer task';
				|it = 'Terminare 
				| lo spostamento delle merci';
				|pl = 'Zakończyć 
				|przenoszenie towarów';
				|tr = 'Mal 
				|transferini tamamla'"));
			
			CancelButton_2 = NewDialogButton(
				"CancelJobExecution", 
				NStr("vi = 'Hủy bỏ 
				|điều chuyển hàng hóa';
				|ru = 'Отменить 
				|перемещение товаров';
				|en = 'Cancel
				|transfer task'; fa = 'Cancel
				|transfer task';
				|it = 'Annullare 
				|lo spostamento delle merci';
				|pl = 'Anulować 
				|przenoszenie towarów';
				|tr = 'Mal 
				|transferini iptal et'"));
			
			If Form.ModeSettings.SelectionScanned Then
				QueryText = NStr("vi = 'Kết thúc 
					|điều chuyển hàng hóa?';
					|ru = 'Завершить 
					|перемещение товаров?';
					|en = 'Finish
					|transfer task?'; fa = 'Finish
					|transfer task?';
					|it = 'Terminare 
					| lo spostamento delle merci?';
					|pl = 'Zakończyć 
					|przenoszenie towarów?';
					|tr = 'Mal 
					|transferi tamamlansın mı?'");
				Buttons.Add(ContinueButton);
				Buttons.Add(FinishButton);
			Else
				If ThereAreScannedProducts(Form) Then
					QueryText = NStr("vi = 'Kết thúc 
					|điều chuyển hàng hóa?';
					|ru = 'Завершить 
					|перемещение товаров?';
					|en = 'Finish
					|transfer task?'; fa = 'Finish
					|transfer task?';
					|it = 'Terminare 
					| lo spostamento delle merci?';
					|pl = 'Zakończyć 
					|przenoszenie towarów?';
					|tr = 'Mal 
					|transferi tamamlansın mı?'");
					Buttons.Add(ContinueButton);
					Buttons.Add(FinishButton);
				Else
					QueryText = NStr("vi = 'Hủy bỏ 
					|điều chuyển hàng hóa?';
					|ru = 'Отменить 
					|перемещение товаров?';
					|en = 'Cancel
					|transfer task?'; fa = 'Cancel
					|transfer task?';
					|it = 'Annullare 
					|lo spostamento delle merci?';
					|pl = 'Anulować 
					|przenoszenie towarów?';
					|tr = 'Mal 
					|transferi iptal edilsin mi?'");
					Buttons.Add(ContinueButton);
					Buttons.Add(CancelButton_2);
				EndIf; 
			EndIf;
			
		ElsIf JobType = "PickingCheck" Then
			
			ContinueButton = NewDialogButton(
				"GoToThePreviousPage", 
				NStr("vi = 'Tiếp tục 
				|kiểm tra lấy ra hàng hóa';
				|ru = 'Продолжить 
				|проверку отбора товаров';
				|en = 'Resume
				|follow-up check'; fa = 'Resume
				|follow-up check';
				|it = 'Continuare 
				| la verifica della selezione delle merci';
				|pl = 'Kontynuować 
				|weryfikację wyboru towarów';
				|tr = 'Ürün filtre 
				|kontrolüne devam et'"), True);
			
			FinishButton = NewDialogButton(
				"FinishJobExecution", 
				NStr("vi = 'Kết thúc 
				|kiểm tra lấy ra hàng hóa';
				|ru = 'Завершить 
				|проверку отбора товаров';
				|en = 'Finish
				|follow-up check'; fa = 'Finish
				|follow-up check';
				|it = 'Terminare 
				| la verifica della selezione delle merci';
				|pl = 'Zakończyć 
				|weryfikację wyboru towarów';
				|tr = 'Ürün filtre 
				|kontrolünü tamamla'"));
			
			CancelButton_2 = NewDialogButton(
				"CancelJobExecution", 
				NStr("vi = 'Hủy bỏ 
				|kiểm tra lấy ra hàng hóa';
				|ru = 'Отменить 
				|проверку отбора товаров';
				|en = 'Cancel
				|follow-up check'; fa = 'Cancel
				|follow-up check';
				|it = 'Annullare 
				|la verifica della selezione delle merci';
				|pl = 'Anulować 
				|weryfikację wyboru towarów';
				|tr = 'Ürün filtre 
				|kontrolünü iptal et'"));
			
			Buttons.Add(ContinueButton);
			
			If ThereAreScannedProducts(Form) Then
				QueryText = NStr("vi = 'Kết thúc
				|kiểm tra lấy ra hàng hóa?';
				|ru = 'Завершить
				|проверку отбора товаров?';
				|en = 'Finish
				|follow-up check?'; fa = 'Finish
				|follow-up check?';
				|it = 'Terminare 
				| la verifica della selezione delle merci?';
				|pl = 'Zakończyć
				|weryfikację wyboru towarów?';
				|tr = 'Ürün filtre 
				|kontrolünü tamamla?'");
				Buttons.Add(FinishButton);
			Else
				QueryText = NStr("vi = 'Hủy bỏ
				|kiểm tra lấy ra hàng hóa?';
				|ru = 'Отменить
				|проверку отбора товаров?';
				|en = 'Cancel
				|follow-up check?'; fa = 'Cancel
				|follow-up check?';
				|it = 'Annullare 
				|la verifica della selezione delle merci?';
				|pl = 'Anulować
				|weryfikację wyboru towarów?';
				|tr = 'Ürün filtre 
				|kontrolünü iptal et?'");
				Buttons.Add(CancelButton_2);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ShowMessageDialog(Form, QueryText, Buttons);
	
EndProcedure

// Called when the Cancel button is clicked on the value selection page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SelectingTheCancelValue(Form) Export
	
	If Form.MarkTheBinForRecount Then
		
		Form.EnteringBarcodeIsCanceled = True;
		Form.BarcodeOfTheScanParameter = "";
		
		GoToThePreviousPage(Form);
		
	Else
		
		Form.EnteringBarcodeIsCanceled = True;
		Form.BarcodeOfTheScanParameter = "";
		Form.SeriesShelfLife = "";
		
		GoToPage3(Form,"ScanPage");
		
	EndIf;
	
EndProcedure

// Switches to the form page, switches focus to the element on the current page.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** Jobs - FormTable - a table containing information about warehouse tasks.
// 			** GroupInputFieldWeight - FormGroup - a group containing information about the product's weight indicators.
// 			** LabelUnitOfMeasurementWeight - FormField - information label for the user interface.
// 			** GroupInputFieldVolume - FormGroup - a group containing information about the product's weight indicators.
// 			** LabelUnitOfMeasurementVolume - FormField - information label for the user interface.
// 			** LabelHintEnterQuantity - FormField - information label for the user interface.
// 			** LabelHintRequestForInformation - FormField - information label for the user interface.
// 			** StorageBinLocation - FormField - field for entering the address of the storage cell.
// 			** ReceivingShippingAreas - FormTable - a table containing information about the warehouse's acceptance zones and shipments.
//	PageName - String - page name.
//
Procedure GoToPage3(Form, PageName) Export
	
	Items = Form.Items;
	CurrentItem = Form.CurrentItem;
	WebServiceMode = Form.WebServiceMode;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	CurrentPage = Items[PageName];
	
	If CurrentPage = Items.OperationSelectionPage Then
		
		ModeSettings.Mode = "OperationSelection";
		
		ClearPageTrafficHistory(Form);
		
		TitleText = CaptionTextOfFormElementTitle("HeaderSelects", Form);
		SetFormHeader(Form, TitleText);
		CurrentItem = Items.MainMenuSelection;
		
	ElsIf CurrentPage = Items.PageJobSelection Then
		
		ModeSettings.Mode = "SelectJob";
		Items.Jobs.Enabled = True;
		CurrentItem = Items.Jobs;
		
	ElsIf CurrentPage = Items.ScanPage Then
		
		ModeSettings.Mode = "Scanning";
		SetParametersForScanItems(Form);
		CurrentItem = ?(JobType = "Receiving"
								Or JobType = "PickingCheck",
							Items.ScanTheProduct,
							Items.ScanCell);
		
	ElsIf CurrentPage = Items.EnterQuantityPage Then
		
		Form.EnteringQuantityIsCanceled = False;
		
		TitleText = NStr("vi = 'Hãy nhập số lượng';
						|ru = 'Введите кол-во';
						|en = 'Enter quantity'; fa = 'ورود مقدار';
						|it = 'Inserire la quantità';
						|pl = 'Wpisz ilość';
						|tr = 'Miktar girin'");
		ToolTipText = NStr("vi = 'Hãy nhập số lượng hàng hóa đã quét.';
							|ru = 'Введите количество отсканированных товаров.';
							|en = 'Enter the quantity of the scanned items.'; fa = 'Enter the quantity of the scanned items.';
							|it = 'Inserite la quantità delle merci scansionate.';
							|pl = 'Wpisz ilość zeskanowanych towarów.';
							|tr = 'Taranan ürün sayısını girin.'");
		
		If ModeSettings.Mode = "EnteringQuantityAsIntended" Then
			
			ToolTipText = NStr("vi = 'Hãy nhập số lượng hàng hóa đã quét theo mục đích được chọn.';
								|ru = 'Введите количество уже отсканированного товара по выбранному назначению.';
								|en = 'Enter the quantity of the scanned items that has the current assignment.'; fa = 'Enter the quantity of the scanned items that has the current assignment.';
								|it = 'Inserite la quantità di merci già scansionate per la destinazione selezionata.';
								|pl = 'Wpisz ilość już zeskanowanego towaru według wybranego przeznaczenia.';
								|tr = 'Seçilen atamaya göre önceden taranan ürünlerin miktarını girin.'");
			
		ElsIf JobType = "PickingCheck" Then
			
			If ModeSettings.Mode = "EnteringQuantityNotToShip" Then
				ToolTipText = NStr("vi = 'Hãy nhập số lượng hàng hóa không cần giao.';
									|ru = 'Введите количество товара которое не надо отгружать.';
									|en = 'Enter the item quantity that shouldn''t be shipped.'; fa = 'Enter the item quantity that shouldn''t be shipped.';
									|it = 'Inserire la quantità di merci che non deve essere spedita.';
									|pl = 'Wpisz ilość towaru, który nie trzeba wysyłać.';
									|tr = 'Sevk edilmemesi gereken ürün miktarını girin.'");
			EndIf;
			
		EndIf;
		
		SetFormHeader(Form, TitleText);
		DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
		
		If JobType = "Filter"
			Or JobType = "Location"
			Or JobType = "Move"
			Or JobType = "PickingCheck" Then
			
			If ValueIsFilled(CurrentScanningLine.Package)
				Or (Not ValueIsFilled(CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				Items.EnterTheNumberOfTheNumber.EditFormat = "ND=15; NFD=0";
				
			Else
				Items.EnterTheNumberOfTheNumber.EditFormat = "";
			EndIf;
			
		Else
			Items.EnterTheNumberOfTheNumber.EditFormat = "";
		EndIf;
		
		If Not ThisIsTara(CurrentScanningLine)
			And (CurrentScanningLine.PackageWeight <> 0) Then
			
			UnitOfMeasureForWeight = ?(WebServiceMode,
									CurrentScanningLine.NameOfWeightUnitOfMeasure,
									CurrentScanningLine.UnitOfMeasureForWeight);
			
			TitleWeight = NStr("vi = 'Trọng lượng, %UnitOfMeasure%';
								|ru = 'Вес, %UnitOfMeasure%';
								|en = 'Weight, %UnitOfMeasure%'; fa = 'Weight, %UnitOfMeasure%';
								|it = 'Peso, %UnitOfMeasure%';
								|pl = 'Waga, %UnitOfMeasure%';
								|tr = 'Ağırlık, %UnitOfMeasure%'");
			TitleWeight = StrReplace(TitleWeight, "%UnitOfMeasure%", UnitOfMeasureForWeight);
			
			Items.GroupInputFieldWeight.Enabled = True;
			Items.LabelUnitOfMeasurementWeight.Title = TitleWeight;
			
		Else
			Items.GroupInputFieldWeight.Enabled = False;
			Items.LabelUnitOfMeasurementWeight.Title = NStr("vi = 'Trọng lượng';
															|ru = 'Вес';
															|en = 'Weight'; fa = 'وزن';
															|it = 'Peso';
															|pl = 'Weight';
															|tr = 'Ağırlık'");
		EndIf;
		
		If Not ThisIsTara(CurrentScanningLine)
			And (CurrentScanningLine.PackageVolume <> 0) Then
			
			UnitOfMeasureForVolume = ?(WebServiceMode,
										CurrentScanningLine.NameOfVolumeUnitOfMeasure,
										CurrentScanningLine.UnitOfMeasureForVolume);
			
			VolumeHeader = NStr("vi = 'Khối lượng,%UnitOfMeasure%';
								|ru = 'Объем, %UnitOfMeasure%';
								|en = 'Volume, %UnitOfMeasure%'; fa = 'Volume, %UnitOfMeasure%';
								|it = 'Volume, %UnitOfMeasure%';
								|pl = 'Objętość, %UnitOfMeasure%';
								|tr = 'Hacim, %UnitOfMeasure%'");
			VolumeHeader = StrReplace(VolumeHeader, "%UnitOfMeasure%", UnitOfMeasureForVolume);
			
			Items.GroupInputFieldVolume.Enabled = True;
			Items.LabelUnitOfMeasurementVolume.Title = VolumeHeader;
			
		Else
			Items.GroupInputFieldVolume.Enabled = False;
			Items.LabelUnitOfMeasurementVolume.Title = NStr("vi = 'Khối lượng';
															|ru = 'Объем';
															|en = 'Volume'; fa = 'حجم';
															|it = 'Volume';
															|pl = 'Volume';
															|tr = 'Hacim'");
		EndIf;
		
		Items.LabelHintEnterQuantity.Title = ToolTipText;
		CurrentItem = Items.EnterTheNumberOfTheNumber;
		
	ElsIf CurrentPage = Items.RequestInformationPage Then
		
		Form.EnteringBarcodeIsCanceled = False;
		Form.BarcodeOfTheScanParameter = "";
		ModeSettings.Mode = "RequestInformation";
		
		If Not Form.MarkTheBinForRecount Then
			
			TitleText = CaptionTextOfFormElementTitle("HeaderOfInformationReceived", Form);
			ToolTipText = CaptionTextOfFormElementTitle("CellProductReboundHint", Form);
			
			SetFormHeader(Form, TitleText);
			Items.LabelHintRequestForInformation.Title = ToolTipText;
			Items.PagesInformationTableMarkCells.CurrentPage = Items.PageInformationTable;
			
			Items.InformationClose.Visible = True;
			CurrentItem = Items.InformationClose;
			
		Else
			
			TitleText = CaptionTextOfFormElementTitle("TitleForMarkingCellForRecalculation", Form);
			ToolTipText = CaptionTextOfFormElementTitle("HintCellBounceToRecalculate", Form);
			
			SetFormHeader(Form, TitleText);
			
			Items.LabelHintRequestForInformation.Title = ToolTipText;
			Items.PagesInformationTableMarkCells.CurrentPage = Items.PageCellMark;
			Items.StorageBinLocation.Enabled = True;
			Items.InformationClose.Visible = False;
			
			CurrentItem = Items.StorageBinLocation;
			
		EndIf;
		
	ElsIf CurrentPage = Items.MessagePage Then
		
		ModeSettings.Mode = "ActionChoice";
		Items.Jobs.Enabled = False;
		Items.ReceivingShippingAreas.Enabled = False;
		CurrentItem = Items.CaptionMessageText;
		
	ElsIf CurrentPage = Items.SelectValuePage Then
		
		Form.EnteringBarcodeIsCanceled = False;
		ModeSettings.Mode = "EnterValue";
		
		TitleText = NStr("vi = 'Nhập mã vạch';
						|ru = 'Ввод штрихкода';
						|en = 'Enter barcode'; fa = 'Enter barcode';
						|it = 'Inserimento del codice a barre';
						|pl = 'Wpisanie kodu kreskowego';
						|tr = 'Barkod girişi'");
		SetFormHeader(Form, TitleText);
		
		SeriesShelfLife = "";
		BarcodeOfTheScanParameter = "";
		
		CurrentItem = Items.BarcodeOfTheScanParameter;
		
	ElsIf CurrentPage = Items.SelectAShippingAcceptanceZonePage Then
		
		ModeSettings.Mode = "SelectionOfPlacementAcceptanceZone";
		Items.ReceivingShippingAreas.Enabled = True;
		CurrentItem = Items.ReceivingShippingAreas;
		
	ElsIf CurrentPage = Items.PageService Then
		
		TitleText = NStr("vi = 'Công cụ';
						|ru = 'Сервис';
						|en = 'Service'; fa = 'خدمت';
						|it = 'Servizio di assistenza';
						|pl = 'Serwis';
						|tr = 'Hizmet'");
		SetFormHeader(Form, TitleText);
		CurrentItem = Items.ServiceTSTSeriesScanMode;
		
	ElsIf CurrentPage = Items.SelectDestinationPage Then
		
		CurrentItem = Items.Assignments;
		
	EndIf;
	
	WhenNavigatingToPage(Form, PageName);
	
	Items.FormPages.CurrentPage = CurrentPage;
	SetHotkeysOnCurPage(Form);
	
	Form.CurrentItem = CurrentItem;
	
EndProcedure

// The procedure is called when you click "Next" on the product scan page.
// Depending on the task type and the current status of the task,
// the dialog structure is formed - the text of the message about the composition of the buttons. Then a dialog 
// message is displayed.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ScanNext(Form) Export
	
	Var TaskTypePresentation, ExecutionType, ActionType;
	
	WebServiceMode = Form.WebServiceMode;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	CellNumber = CurrentScanningLine.CellNumber;
	NumberOfBins = CurrentScanningLine.NumberOfBins;
	
	ThisIsLastCell = ThisIsLastCell(Form);
	ThisIsLastItemInCell = ThisIsLastItemInCell(Form);
	ThisIsLastLineOfScan = ThisIsLastLineOfScan(Form);
	ThereAreScannedProducts = ThereAreScannedProducts(Form);
	ThereAreScannedItemsInCurCell = ValueIsFilled(CurrentScanningLine.SKProducts);
	ThereIsScannedCell = ValueIsFilled(CurrentScanningLine.SKCell);
	
	GoodsPresentation = ?(WebServiceMode,
		GoodsPresentation(CurrentScanningLine.ItemName,
			CurrentScanningLine.ItemVariantName),
		GoodsPresentation(CurrentScanningLine.Products,
			CurrentScanningLine.Characteristic));
	
	GetValuesOfMessageElementsToUser(JobType, SelectionScanned, TaskTypePresentation,
		ExecutionType, ActionType);
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	// Depending on the type of operation, form a question text and a list of dialog buttons.
	Buttons = New ValueList;
	
	If ThisIsSetOfGoods Then
		
		If JobType = "Location" Then
			
			If ThereAreScannedProducts Then
				
				QueryText = NStr("vi = 'Kết thúc 
					|thêm hàng hóa và chuyển sang xếp vào ô hàng?';
					|ru = 'Завершить 
					|добавление товаров и перейти к размещению по ячейкам?';
					|en = 'Do you want to finish selection
					|and proceed to Put-away list?'; fa = 'Do you want to finish selection
					|and proceed to Put-away list?';
					|it = 'Terminare 
					| l''aggiunta delle merci e passare al collocamento nelle celle?';
					|pl = 'Zakończyć 
					|dodawanie towarów i przejść do umieszczenia w komórkach?';
					|tr = 'Ürün eklemeyi tamamla 
					|ve hücrelere göre yerleştirmeye git?'");
				
				FinishButton = NewDialogButton(
					"FinishJobExecution", 
					NStr("vi = 'Chuyển đến 
						|xếp vào hàng hóa';
						|ru = 'Перейти 
						|к размещению товаров';
						|en = 'Go to
						|put-away list'; fa = 'Go to
						|put-away list';
						|it = 'Passare 
						| al collocamento delle merci';
						|pl = 'Przejść 
						|do umieszczenia towarów';
						|tr = 'Ürün yerleştirmeye 
						|git'"));
				
			Else
				
				QueryText = NStr("vi = 'Hủy bỏ 
				|thêm hàng hóa vào nhiệm vụ xếp vào?';
				|ru = 'Отменить 
				|добавление товаров в задание на размещение?';
				|en = 'Undo adding items
				|to the Put-away task?'; fa = 'Undo adding items
				|to the Put-away task?';
				|it = 'Annullare 
				| l''aggiunta delle merci nel task per il collocamento?';
				|pl = 'Anulować 
				|dodawanie towarów do zadania na umieszczenie?';
				|tr = 'Yerleştirme 
				|görevine ürün eklemeyi iptal et?'");
				
				FinishButton = NewDialogButton(
					"FinishJobExecution", 
					NStr("vi = 'Hủy thực hiện nhiệm vụ';
						|ru = 'Отменить выполнение задания';
						|en = 'Cancel task'; fa = 'لغو وظیفه';
						|it = 'Annulla completamento task';
						|pl = 'Anuluj wykonanie zadania';
						|tr = 'Görevin gerçekleştirilmesini iptal et'"));
				
			EndIf;
			
			ContinueButton = NewDialogButton(
				"GoToScanning", 
				NStr("vi = 'Tiếp tục 
					|thêm hàng hóa';
					|ru = 'Продолжить 
					|добавление товаров';
					|en = 'Resume
					|adding items'; fa = 'Resume
					|adding items';
					|it = 'Continuare 
					|l''aggiunta delle merci';
					|pl = 'Kontynuować 
					|dodawanie towarów';
					|tr = 'Ürün 
					|eklemeye devam et'"));
			
		ElsIf JobType = "Receiving" Then
			
			If ThereAreScannedProducts Then
				
				QueryText = NStr("vi = 'Kết thúc 
					|nhập hàng?';
					|ru = 'Завершить 
					|приемку товаров?';
					|en = 'Finish
					|goods receipt?'; fa = 'Finish
					|goods receipt?';
					|it = 'Terminare 
					|l''accettazione delle merci?';
					|pl = 'Zakończyć 
					|przyjmowanie towarów?';
					|tr = 'Mal 
					|girişini tamamla?'");
				
				FinishButton = NewDialogButton(
					"FinishJobExecution",
					NStr("vi = 'Kết thúc 
						|nhập hàng';
						|ru = 'Завершить 
						|приемку товаров';
						|en = 'Finish
						|goods receipt'; fa = 'Finish
						|goods receipt';
						|it = 'Terminare 
						|l''accettazione delle merci';
						|pl = 'Zakończyć 
						|przyjmowanie towarów';
						|tr = 'Mal 
						|girişini tamamla'"));
				
			Else
				
				QueryText = NStr("vi = 'Hủy 
				|thực hiện nhập hàng?';
				|ru = 'Отменить 
				|выполнение приемки товаров?';
				|en = 'Cancel
				|goods receipt?'; fa = 'Cancel
				|goods receipt?';
				|it = 'Annullare 
				| l''esecuzione dell''accettazione delle merci?';
				|pl = 'Anulować 
				|wykonywanie przyjmowania towarów';
				|tr = 'Mal 
				|girişinin gerçekleştirilmesini iptal et?'");
				
				FinishButton = NewDialogButton(
					"FinishJobExecution",
					NStr("vi = 'Hủy 
						|nhập hàng';
						|ru = 'Отменить 
						|приемку товаров';
						|en = 'Cancel
						|goods receipt'; fa = 'Cancel
						|goods receipt';
						|it = 'Annullare 
						| l''accettazione delle merci';
						|pl = 'Anulować 
						|przyjmowanie towarów';
						|tr = 'Mal 
						|girişini iptal et'"));
				
			EndIf;
			
			ContinueButton = NewDialogButton(
				"GoToThePreviousPage",
				NStr("vi = 'Tiếp tục 
					|nhập hàng';
					|ru = 'Продолжить 
					|приемку товаров';
					|en = 'Resume
					|goods receipt'; fa = 'Resume
					|goods receipt';
					|it = 'Continuare 
					| l''accettazione delle merci';
					|pl = 'Kontynuować 
					|przyjmowanie towarów';
					|tr = 'Mal 
					|girişini sürdür'"));
			
		EndIf;
		
		ContinueButton.Select_ = True;
		
		Buttons.Add(ContinueButton);
		Buttons.Add(FinishButton);
		
	ElsIf JobType = "Recalculate" Then
		
		ContinueButton = NewDialogButton(
			"GoToThePreviousPage", 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tiếp tục 
					|kiểm đếm hàng hóa trong ô hàng %1';
					|ru = 'Продолжить 
					|пересчет товаров в ячейке %1';
					|en = 'Resume inventory count in
					|storage bin %1'; fa = 'Resume inventory count in
					|storage bin %1';
					|it = 'Continuare 
					| il ricalcolo delle merci nella cella %1';
					|pl = 'Kontynuować 
					|przeliczanie towarów w komórce %1';
					|tr = '%1 hücresindeki ürünleri saymaya 
					|devam et'"),
				?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell)));
		
		GoToNextCellButton = NewDialogButton(
			"GoToTheNextScanningBin", 
			NStr("vi = 'Chuyển đến ô tiếp theo';
				|ru = 'Перейти к следующей ячейке';
				|en = 'Go to next storage bin'; fa = 'رفتن به محل نگهداری بعدی';
				|it = 'Passare alla cella successiva';
				|pl = 'Przejdź do następnej komórki';
				|tr = 'Sonraki hücreye git'"));
		
		FinishButton = NewDialogButton(
			"FinishJobExecution", 
			NStr("vi = 'Kết thúc 
				|thực hiện nhiệm vụ';
				|ru = 'Завершить 
				|выполнение задания';
				|en = 'Finish
				|task'; fa = 'Finish
				|task';
				|it = 'Completare 
				| l''esecuzione del task';
				|pl = 'Zakończyć 
				|wykonanie zadania';
				|tr = 'Görevi 
				|tamamla'"));
		
		If ThisIsLastCell Then
			
			If ThereIsScannedCell 
				And ThereAreScannedItemsInCurCell Then
				
				MessageText = NStr("vi = 'Ô hàng %1 
					|cuối cùng trong nhiệm vụ kiểm đếm.
					|
					|Kết thúc thực hiện 
					|kiểm đếm hàng hóa?';
					|ru = 'Ячейка %1 
					|последняя в задании на пересчет.
					|
					|Завершить выполнение 
					|пересчета товаров?';
					|en = 'Storage bin %1 
					|is the last one in the recount job.
					|
					|Finish
					|the inventory count?'; fa = 'Storage bin %1 
					|is the last one in the recount job.
					|
					|Finish
					|the inventory count?';
					|it = 'La cella %1 
					| è l''ultima nel task per il ricalcolo.
					|
					|Completare 
					| il ricalcolo delle merci?';
					|pl = 'Komórka %1 
					|jest ostatnia w zadaniu na przeliczanie.
					|
					|Zakończyć wykonanie 
					|przeliczenia towarów?';
					|tr = '%1 hücresi, yeniden sayım görevindeki 
					|son hücredir.
					|
					|Ürünlerin yeniden sayılmasını 
					|bitir?'");
				
			ElsIf ThereIsScannedCell 
				And Not ThereAreScannedItemsInCurCell Then
				
				MessageText = NStr("vi = 'Ô hàng %1 
					|là cuối cùng trong nhiệm vụ kiểm đếm,
					|và trong đó vẫn chưa quét mặt hàng nào.
					|
					|Kết thúc 
					|kiểm đếm hàng hóa?';
					|ru = 'Ячейка %1 
					|последняя в задании на пересчет,
					|и в ней не было отсканировано ни одного товара.
					|
					|Завершить выполнение 
					|пересчета товаров?';
					|en = 'Storage bin %1
					|is the last one in the recount task.
					|No goods were scanned in the storage bin.
					|
					|Do you want to finish 
					|the task?'; fa = 'Storage bin %1
					|is the last one in the recount task.
					|No goods were scanned in the storage bin.
					|
					|Do you want to finish 
					|the task?';
					|it = 'La cella %1 
					| è l''ultima nel task per il ricalcolo, 
					| in questa cella non è stata scansionata nessuna merce.
					|
					|Completare 
					|il ricalcolo delle merci?';
					|pl = 'Komórka %1 
					|jest ostatnia w zadaniu na przeliczanie,
					|i w niej nie został zeskanowany żaden towar.
					|
					|Zakończyć wykonanie 
					|przeliczenia towarów?';
					|tr = '%1 hücresi 
					|yeniden sayım işindeki son hücredir
					|ve içinde hiçbir ürün taranmadı.
					|
					|Ürünlerin yeniden 
					|sayılmasını bitir?'");
				
			Else
				MessageText = NStr("vi = 'Ô hàng %1 vẫn chưa được quét.
					|
					|Kết thúc 
					|kiểm đếm hàng hóa?';
					|ru = 'Ячейка %1 не была отсканирована.
					|
					|Завершить выполнение 
					|пересчета товаров?';
					|en = 'Storage bin %1 was not scanned.
					|
					|Finish
					|the inventory count?'; fa = 'Storage bin %1 was not scanned.
					|
					|Finish
					|the inventory count?';
					|it = 'La cella %1 non è stata scansionata.
					|
					| Completare 
					|il ricalcolo delle merci?';
					|pl = 'Komórka %1 nie została zeskanowana.
					|
					|Zakończyć wykonanie 
					|przeliczenia towarów?';
					|tr = '%1 hücresi taranmadı.
					|
					|Ürünün yeniden sayımını bitir 
					|?'");
			EndIf;
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageText,
				?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
			
			FinishButton.Select_ = True;
			
			Buttons.Add(ContinueButton);
			Buttons.Add(FinishButton);
			
		Else
			
			If ThereIsScannedCell 
				And ThereAreScannedItemsInCurCell Then
				
				QueryText = NStr("vi = 'Chưa kết thúc thực hiện nhiệm vụ kiểm đếm hàng hóa 
					|trong ô hàng.';
					|ru = 'Выполнение задания по пересчету товаров 
					|в ячейке не закончено.';
					|en = 'Physical count
					|not finished.'; fa = 'Physical count
					|not finished.';
					|it = 'Il task di ricalcolo delle merci 
					|nella cella non è completato.';
					|pl = 'Wykonanie zadania na przeliczanie towarów 
					|w komórce nie zakończono.';
					|tr = 'Hücredeki ürünleri yeniden sayma 
					|görevi tamamlanmadı.'");
				
			ElsIf ThereIsScannedCell 
				And Not ThereAreScannedItemsInCurCell Then
				
				QueryText = NStr("vi = 'Trong ô hàng vẫn chưa quét mặt hàng nào.
					|Sau khi chuyển đến kiểm đếm hàng hóa trong ô hàng tiếp theo thì sẽ không thể quay lại ô hàng hiện tại.
					|
					|Chuyển đến kiểm đếm hàng hóa trong ô hàng tiếp theo?';
					|ru = 'В ячейке не было отсканировано ни одного товара.
					|После перехода к пересчету товаров в следующей ячейке возврат к текущей будет невозможен.
					|
					|Перейти к пересчету товаров в следующей ячейке?';
					|en = 'You didn''t scan items in this storage bin.
					|If you skip it now, you will not be able to return to this bin.
					|
					|Do you want to skip this bin and proceed to the next one?'; fa = 'You didn''t scan items in this storage bin.
					|If you skip it now, you will not be able to return to this bin.
					|
					|Do you want to skip this bin and proceed to the next one?';
					|it = 'Nella cella non è stata scansionata nessuna merce.
					| Dopo il passaggio al ricalcolo delle merci nella cella successiva non sarà possibile tornare alla cella corrente.
					|
					|Passare al ricalcolo delle merci nella cella successiva?';
					|pl = 'W komórce nie został zeskanowany żaden towar.
					|Po przejściu do przeliczania towarów w następnej komórce powrót do bieżącej będzie niemożliwy.
					|
					|Przejść do przeliczania towarów w kolejnej komórce?';
					|tr = 'Hücrede ürün sayımı yapılmadı.
					|Bir sonraki hücrede ürün yeniden sayımına geçildikten sonra mevcut hücreye geri dönülemez.
					|
					|Bir sonraki hücrede ürünün yeniden sayımına geçilsin mi?'");
				
			ElsIf Not ThereIsScannedCell Then 
				
				QueryText = NStr("vi = 'Chưa quét ô hàng %1.
					|Sau khi chuyển đến kiểm đếm hàng hóa trong ô hàng tiếp theo, sẽ không thể quay lại ô hàng hiện tại.
					|
					|Chuyển đến kiểm đếm hàng hóa trong ô hàng tiếp theo?';
					|ru = 'Ячейка %1 не была отсканирована.
					|После перехода к пересчету товаров в следующей ячейке возврат к текущей будет невозможен.
					|
					|Перейти к пересчету товаров в следующей ячейке?';
					|en = 'You didn''t scan items in storage bin %1.
					|If you skip it now, you will not be able to return to this bin.
					|
					|Do you want to skip this bin and proceed to the next one?'; fa = 'You didn''t scan items in storage bin %1.
					|If you skip it now, you will not be able to return to this bin.
					|
					|Do you want to skip this bin and proceed to the next one?';
					|it = 'La cella %1 non è stata scansionata. 
					|Dopo il passaggio al ricalcolo delle merci nella cella successiva non sarà possibile tornare alla cella corrente. 
					|
					|Passare al ricalcolo delle merci nella cella successiva?';
					|pl = 'Komórka %1 nie została zeskanowana.
					|Po przejściu do przeliczania towarów w następnej komórce powrót do bieżącej będzie niemożliwy.
					|
					|Przejść do przeliczania towarów w kolejnej komórce?';
					|tr = '%1 hücresi taranmadı.
					|Bir sonraki hücrede ürün yeniden sayımına geçildikten sonra mevcut hücreye geri dönülemeyecek.
					|
					|Bir sonraki hücrede ürün yeniden sayımına geçilsin mi?'");
				
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					QueryText, 
					?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
				
			EndIf;
			
			GoToNextCellButton.Select_ = True;
			
			Buttons.Add(GoToNextCellButton);
			Buttons.Add(ContinueButton);
			Buttons.Add(FinishButton);
			
		EndIf;
		
	ElsIf JobType = "Filter" Then
		
		ContinueButton = NewDialogButton(
			"GoToThePreviousPage", 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tiếp tục 
					|lọc hàng hóa từ ô %1';
					|ru = 'Продолжить 
					|отбор товаров из ячейки %1';
					|en = 'Resume picking items from
					|storage bin %1'; fa = 'Resume picking items from
					|storage bin %1';
					|it = 'Continuare 
					| la selezione delle merci dalla cella %1';
					|pl = 'Kontynuować 
					|wybór towarów z komórki %1';
					|tr = '%1 hücresinden 
					|ürünleri seçmeye devam et'"), 
			?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell)));
		
		GoToNextCellButton = NewDialogButton(
			"GoToTheNextScanningBin",
			NStr("vi = 'Chuyển 
				|đến ô tiếp theo';
				|ru = 'Перейти 
				|к следующей ячейке';
				|en = 'Go to
				|next bin'; fa = 'Go to
				|next bin';
				|it = 'Passare 
				|alla cella successiva';
				|pl = 'Przejść 
				| do następnej komórki';
				|tr = 'Sonraki hücreye 
				|git'"));
		
		GoToNextProductButton = NewDialogButton(
			"GoToTheNextScanningGoods",
			NStr("vi = 'Chuyển sang 
				|mặt hàng tiếp theo';
				|ru = 'Перейти 
				|к следующему товару';
				|en = 'Go to
				|next item'; fa = 'Go to
				|next item';
				|it = 'Passare 
				| alla merce successiva';
				|pl = 'Przejść 
				|do następnego towaru';
				|tr = 'Sonraki ürüne 
				|git'"));
		
		FinishButton = NewDialogButton(
			"FinishJobExecution",
			NStr("vi = 'Kết thúc 
				|thực hiện nhiệm vụ';
				|ru = 'Завершить 
				|выполнение задания';
				|en = 'Finish
				|task'; fa = 'Finish
				|task';
				|it = 'Completare 
				| l''esecuzione del task';
				|pl = 'Zakończyć 
				|wykonanie zadania';
				|tr = 'Görevi 
				|tamamla'"));
		
		GetButton = NewDialogButton(
			"AddGoods",
			NStr("vi = 'Tiếp tục 
				|lọc hàng hóa trong các ô khác';
				|ru = 'Продолжить
				|отбор товаров в других ячейках';
				|en = 'Resume picking items from
				|other storage bins'; fa = 'Resume picking items from
				|other storage bins';
				|it = 'Continuare 
				|la selezione delle merci nelle altre celle';
				|pl = 'Kontynuować
				|wybór towarów w innych komórkach';
				|tr = 'Diğer hücrelerde
				|ürün seçimine devam et'"));
		
		If Not (NumberOfBins = CellNumber) Then
			
			QueryText = NStr("vi = 'Chưa kết thúc nhiệm vụ lọc.';
							|ru = 'Задание по отбору не закончено.';
							|en = 'Picking is not finished.'; fa = 'Picking is not finished.';
							|it = 'Il task di selezione non è terminato.';
							|pl = 'Zadanie na wybór nie zakończono.';
							|tr = 'Filtre görevi bitmedi.'");
			
			Buttons.Add(GoToNextCellButton);
			
			If ThereIsScannedCell Then
				Buttons.Add(GoToNextProductButton);
			EndIf;
			
			Buttons.Add(ContinueButton);
			Buttons.Add(FinishButton);
			
		ElsIf Not ThisIsLastItemInCell Then
			
			QueryText = NStr("vi = 'Chưa kết thúc nhiệm vụ lọc.';
							|ru = 'Задание по отбору не закончено.';
							|en = 'Picking is not finished.'; fa = 'Picking is not finished.';
							|it = 'Il task di selezione non è terminato.';
							|pl = 'Zadanie na wybór nie zakończono.';
							|tr = 'Filtre görevi bitmedi.'");
			
			If Not Form.GoodsAreSelected Then
				Buttons.Add(GetButton);
			EndIf;
			
			If ThereIsScannedCell Then
				Buttons.Add(GoToNextProductButton);
			EndIf;
			
			Buttons.Add(ContinueButton);
			Buttons.Add(FinishButton);
			
		ElsIf (NumberOfBins = CellNumber)
			And ThisIsLastItemInCell Then
			
			If Not ThereAreScannedItemsInCurCell Or ThisIsLastLineOfScan Then
				
				ReplacementParameters = New Structure;
				
				ReplacementParameters.Insert("OwnGoods", GoodsPresentation);
				ReplacementParameters.Insert("Cell",
					?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
				ReplacementParameters.Insert("JobType", TaskTypePresentation);
				ReplacementParameters.Insert("ExecutionType", ExecutionType);
				
				QueryText = StringFunctionsClientServer.InsertParametersIntoString(
					NStr("vi = 'Hàng hóa ""[OwnGoods]"" 
						|trong ô hàng ""[Cell]"" 
						|là cuối cùng trong nhiệm vụ [JobType].
						|
						|Kết thúc thực hiện 
						|[ExecutionType] hàng hóa?';
						|ru = 'Товар ""[OwnGoods]"" 
						|в ячейке ""[Cell]"" 
						|последний в задании на [JobType].
						|
						|Завершить выполнение 
						|[ExecutionType] товаров?';
						|en = '[ExecutionType] [JobType]. 
						|[OwnGoods] 
						| in bin [Cell] 
						| is the last item in this task.
						|
						|Do you want to finish the task?'; fa = '[ExecutionType] [JobType]. 
						|[OwnGoods] 
						| in bin [Cell] 
						| is the last item in this task.
						|
						|Do you want to finish the task?';
						|it = 'Merce ""[OwnGoods]"" 
						|nella cella ""[Cell]"" 
						| è l''ultima nel task [JobType].
						|
						|Completare 
						|[ExecutionType] delle merci?';
						|pl = 'Towar ""[OwnGoods]"" 
						|w komórce ""[Cell]"" 
						|ostatni w zadaniu na[JobType].
						|
						|Zakończyć wykonanie 
						|[ExecutionType]towarów?';
						|tr = '""[Cell]"" 
						|hücresindeki ""[OwnGoods]"" 
						|ürün, [JobType]''ndeki görevin sonuncusudur. 
						|
						|
						|[ExecutionType] ürünlerin gerçekleştirilmesini tamamla?'"), 
					ReplacementParameters);
				
			Else
				QueryText = NStr("vi = 'Chưa kết thúc nhiệm vụ lọc.';
								|ru = 'Задание по отбору не закончено.';
								|en = 'Picking is not finished.'; fa = 'Picking is not finished.';
								|it = 'Il task di selezione non è terminato.';
								|pl = 'Zadanie na wybór nie zakończono.';
								|tr = 'Filtre görevi bitmedi.'");
			EndIf;
			
			If Not Form.GoodsAreSelected Then
				Buttons.Add(GetButton);
			EndIf;
			
			If Not ThisIsLastLineOfScan Then
				Buttons.Add(GoToNextProductButton);
			EndIf;
			
			Buttons.Add(ContinueButton);
			Buttons.Add(FinishButton);
			
		EndIf;
		
	ElsIf JobType = "Location" Then
		
		ContinueButton = NewDialogButton(
			"GoToThePreviousPage", 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tiếp tục 
					|xếp hàng hóa vào ô %1';
					|ru = 'Продолжить 
					|размещение товаров в ячейку %1';
					|en = 'Resume put-away to bin
					|%1'; fa = 'Resume put-away to bin
					|%1';
					|it = 'Continuare 
					| il collocamento delle merci nella cella %1';
					|pl = 'Kontynuować 
					|umieszczanie towarów w komórce %1';
					|tr = '
					| hücresine %1ürün yerleştirmeye devam et'"), 
				?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell)));
		
		GoToNextCellButton = NewDialogButton(
			"GoToTheNextScanningBin",
			NStr("vi = 'Chuyển 
				|đến ô tiếp theo';
				|ru = 'Перейти 
				|к следующей ячейке';
				|en = 'Go to
				|next bin'; fa = 'Go to
				|next bin';
				|it = 'Passare 
				|alla cella successiva';
				|pl = 'Przejść 
				| do następnej komórki';
				|tr = 'Sonraki hücreye 
				|git'"));
		
		GoToNextProductButton = NewDialogButton(
			"GoToTheNextScanningGoods",
			NStr("vi = 'Chuyển sang 
				|mặt hàng tiếp theo';
				|ru = 'Перейти 
				|к следующему товару';
				|en = 'Go to
				|next item'; fa = 'Go to
				|next item';
				|it = 'Passare 
				| alla merce successiva';
				|pl = 'Przejść 
				|do następnego towaru';
				|tr = 'Sonraki ürüne 
				|git'"));
		
		FinishButton = NewDialogButton(
			"FinishJobExecution",
			NStr("vi = 'Kết thúc 
				|xếp vào hàng hóa';
				|ru = 'Завершить 
				|размещение товаров';
				|en = 'Finish
				|put-away task'; fa = 'Finish
				|put-away task';
				|it = 'Terminare 
				| il collocamento delle merci';
				|pl = 'Zakończyć  
				|umieszczenie towarów';
				|tr = 'Ürün 
				|yerleştirmeyi tamamla'"));
		
		GetButton = NewDialogButton(
			"AddGoods",
			NStr("vi = 'Tiếp tục
				|xếp hàng hóa vào các ô khác';
				|ru = 'Продолжить
				|размещение товаров в других ячейках';
				|en = 'Resume putting items in
				|other storage bins'; fa = 'Resume putting items in
				|other storage bins';
				|it = 'Continuare 
				|il collocamento delle merci nelle altre celle';
				|pl = 'Kontynuować 
				|umieszczanie towarów w innych komórkach';
				|tr = 'Ürünlerin diğer hücrelere
				|yerleştirilmesine devam et'"));
		
		If ThisIsProcessingOrderOfItemCell Then
			
			QueryText = NStr("vi = 'Kết thúc sắp xếp hàng hóa?';
							|ru = 'Завершить размещение товаров?';
							|en = 'Finish put-away task?'; fa = 'Finish put-away task?';
							|it = 'Terminare il collocamento delle merci?';
							|pl = 'Zakończyć umieszczanie towarów?';
							|tr = 'Ürün yerleştirmeyi tamamla?'");
			
			ContinueButton = NewDialogButton(
				"GoToThePreviousPage", 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tiếp tục 
						|xếp vào hàng hóa';
						|ru = 'Продолжить 
						|размещение товаров';
						|en = 'Continue
						|put-away task'; fa = 'Continue
						|put-away task';
						|it = 'Continuare 
						| il collocamento delle merci';
						|pl = 'Kontynuować 
						|umieszczenie towarów';
						|tr = 'Ürün 
						|yerleştirmeye devam et'"),
					?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell)));
				
			Buttons.Add(ContinueButton);
			Buttons.Add(FinishButton);
			
		Else
			If Not (NumberOfBins = CellNumber) Then
				
				QueryText = NStr("vi = 'Chưa kết thúc nhiệm vụ 
					|sắp xếp hàng hóa.';
					|ru = 'Задание по размещению товаров 
					|не закончено.';
					|en = 'Put-away
					|is not completed.'; fa = 'Put-away
					|is not completed.';
					|it = 'Task di collocamento delle merci 
					| non è completato.';
					|pl = 'Zadanie na umieszczanie towarów 
					|nie zostało zakończone.';
					|tr = 'Yerleştirme görevi 
					|tamamlanmadı.'");
				
				Buttons.Add(GoToNextCellButton);
				
				If ThereIsScannedCell Then
					Buttons.Add(GoToNextProductButton);
				EndIf;
				
				Buttons.Add(ContinueButton);
				Buttons.Add(FinishButton);
				
			ElsIf Not ThisIsLastItemInCell Then
				
				QueryText = NStr("vi = 'Chưa hoàn tất nhiệm vụ sắp xếp.';
								|ru = 'Задание по размещению не закончено.';
								|en = 'Put-away task is not completed.'; fa = 'Put-away task is not completed.';
								|it = 'Il task di spostamento non è terminato.';
								|pl = 'Zadanie na umieszczanie nie zostało zakończone.';
								|tr = 'Yerleştirme görevi tamamlanmadı.'");
				
				If Not Form.GoodsAreSelected Then
					Buttons.Add(GetButton);
				EndIf;
				
				If ThereIsScannedCell Then
					Buttons.Add(GoToNextProductButton);
				EndIf;
				
				Buttons.Add(ContinueButton);
				Buttons.Add(FinishButton);
				
			ElsIf (NumberOfBins = CellNumber)
				And ThisIsLastItemInCell Then
				
				If Not ThereAreScannedItemsInCurCell
					Or ThisIsLastLineOfScan Then
					
					ReplacementParameters = New Structure;
					
					ReplacementParameters.Insert("OwnGoods", GoodsPresentation);
					ReplacementParameters.Insert("Cell",
						?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
					ReplacementParameters.Insert("JobType", TaskTypePresentation);
					ReplacementParameters.Insert("ExecutionType", ExecutionType);
					
					QueryText = StringFunctionsClientServer.InsertParametersIntoString(
						NStr("vi = 'Hàng hóa ""[OwnGoods]"" 
							|trong ô hàng ""[Cell]"" 
							|là cuối cùng trong nhiệm vụ [JobType].
							|
							|Kết thúc thực hiện 
							|[ExecutionType] hàng hóa?';
							|ru = 'Товар ""[OwnGoods]"" 
							|в ячейке ""[Cell]"" 
							|последний в задании на [JobType].
							|
							|Завершить выполнение 
							|[ExecutionType] товаров?';
							|en = '[ExecutionType] [JobType]. 
							|[OwnGoods] 
							| in bin [Cell] 
							| is the last item in this task.
							|
							|Do you want to finish the task?'; fa = '[ExecutionType] [JobType]. 
							|[OwnGoods] 
							| in bin [Cell] 
							| is the last item in this task.
							|
							|Do you want to finish the task?';
							|it = 'Merce ""[OwnGoods]"" 
							|nella cella ""[Cell]"" 
							| è l''ultima nel task [JobType].
							|
							|Completare 
							|[ExecutionType] delle merci?';
							|pl = 'Towar ""[OwnGoods]"" 
							|w komórce ""[Cell]"" 
							|ostatni w zadaniu na[JobType].
							|
							|Zakończyć wykonanie 
							|[ExecutionType]towarów?';
							|tr = '""[Cell]"" 
							|hücresindeki ""[OwnGoods]"" 
							|ürün, [JobType]''ndeki görevin sonuncusudur. 
							|
							|
							|[ExecutionType] ürünlerin gerçekleştirilmesini tamamla?'"), 
						ReplacementParameters);
					
				Else
					QueryText = NStr("vi = 'Chưa hoàn tất nhiệm vụ sắp xếp.';
									|ru = 'Задание по размещению не закончено.';
									|en = 'Put-away task is not completed.'; fa = 'Put-away task is not completed.';
									|it = 'Il task di spostamento non è terminato.';
									|pl = 'Zadanie na umieszczanie nie zostało zakończone.';
									|tr = 'Yerleştirme görevi tamamlanmadı.'");
				EndIf;
				
				If Not Form.GoodsAreSelected Then
					Buttons.Add(GetButton);
				EndIf;
				
				If Not ThisIsLastLineOfScan Then
					Buttons.Add(GoToNextProductButton);
				EndIf;
					
				Buttons.Add(ContinueButton);
				Buttons.Add(FinishButton);
				
			EndIf;
			
		EndIf;
		
	ElsIf JobType = "Move" Then
		
		ContinueButton = NewDialogButton(
			"GoToThePreviousPage",
			NStr("vi = 'Tiếp tục 
				|quét hàng hóa';
				|ru = 'Продолжить 
				|сканирование товаров';
				|en = 'Resume
				|scanning'; fa = 'Resume
				|scanning';
				|it = 'Continuare
				| la scansione delle merci';
				|pl = 'Kontynuować 
				|skanowanie towarów';
				|tr = 'Ürünleri taramaya 
				|devam et'"));
		
		GoToNextCellButton = NewDialogButton(
			"GoToTheNextScanningBin",
			NStr("vi = 'Chuyển 
				|đến ô tiếp theo';
				|ru = 'Перейти 
				|к следующей ячейке';
				|en = 'Go to
				|next bin'; fa = 'Go to
				|next bin';
				|it = 'Passare 
				|alla cella successiva';
				|pl = 'Przejść 
				| do następnej komórki';
				|tr = 'Sonraki hücreye 
				|git'"));
		
		GoToNextProductButton = NewDialogButton(
			"GoToTheNextScanningGoods",
			NStr("vi = 'Chuyển sang 
				|mặt hàng tiếp theo';
				|ru = 'Перейти 
				|к следующему товару';
				|en = 'Go to
				|next item'; fa = 'Go to
				|next item';
				|it = 'Passare 
				| alla merce successiva';
				|pl = 'Przejść 
				|do następnego towaru';
				|tr = 'Sonraki ürüne 
				|git'"));
		
		FinishButton = NewDialogButton(
			"FinishJobExecution",
			NStr("vi = 'Kết thúc 
				|thực hiện nhiệm vụ';
				|ru = 'Завершить 
				|выполнение задания';
				|en = 'Finish
				|task'; fa = 'Finish
				|task';
				|it = 'Completare 
				| l''esecuzione del task';
				|pl = 'Zakończyć 
				|wykonanie zadania';
				|tr = 'Görevi 
				|tamamla'"));
		
		GoToPlacementButton = NewDialogButton(
			"GoToTheGoodsPlacement",
			NStr("vi = 'Chuyển 
				|đến sắp xếp hàng hóa';
				|ru = 'Перейти 
				|к размещению товаров';
				|en = 'Go to
				|put-away list'; fa = 'Go to
				|put-away list';
				|it = 'Passare 
				| al collocamento delle merci';
				|pl = 'Przejść 
				|do umieszczenia towarów';
				|tr = 'Ürün yerleştirmeye 
				|git'"));
		
		If SelectionScanned Then
			
			If Not ThisIsLastCell Then
				
				If ThisIsProcessingOrderOfItemCell Then
					QueryText = NStr("vi = 'Điều chuyển hàng hóa xong?';
									|ru = 'Завершить перемещение товаров?';
									|en = 'Finish transfer task?'; fa = 'Finish transfer task?';
									|it = 'Terminare lo spostamento delle merci?';
									|pl = 'Zakończyć przenoszenie towarów?';
									|tr = 'Mal transferi tamamlansın mı?'");
				Else
					QueryText = NStr("vi = 'Chưa hoàn tất nhiệm vụ sắp xếp.';
									|ru = 'Задание по размещению не закончено.';
									|en = 'Put-away task is not completed.'; fa = 'Put-away task is not completed.';
									|it = 'Il task di spostamento non è terminato.';
									|pl = 'Zadanie na umieszczanie nie zostało zakończone.';
									|tr = 'Yerleştirme görevi tamamlanmadı.'");
				EndIf;
				
				Buttons.Add(ContinueButton);
				
				If Not ThisIsProcessingOrderOfItemCell Then
					Buttons.Add(GoToNextCellButton);
				EndIf;
				
				If ThereIsScannedCell
					And Not ThisIsProcessingOrderOfItemCell Then
					Buttons.Add(GoToNextProductButton);
				EndIf;
				
				Buttons.Add(FinishButton);
				
			ElsIf Not ThisIsLastItemInCell Then
				
				If ThisIsProcessingOrderOfItemCell Then
					QueryText = NStr("vi = 'Điều chuyển hàng hóa xong?';
									|ru = 'Завершить перемещение товаров?';
									|en = 'Finish transfer task?'; fa = 'Finish transfer task?';
									|it = 'Terminare lo spostamento delle merci?';
									|pl = 'Zakończyć przenoszenie towarów?';
									|tr = 'Mal transferi tamamlansın mı?'");
				Else
					QueryText = NStr("vi = 'Chưa hoàn tất nhiệm vụ sắp xếp.';
									|ru = 'Задание по размещению не закончено.';
									|en = 'Put-away task is not completed.'; fa = 'Put-away task is not completed.';
									|it = 'Il task di spostamento non è terminato.';
									|pl = 'Zadanie na umieszczanie nie zostało zakończone.';
									|tr = 'Yerleştirme görevi tamamlanmadı.'");
				EndIf;
				
				Buttons.Add(ContinueButton);
				
				If ThereIsScannedCell
					And Not ThisIsProcessingOrderOfItemCell Then
					
					Buttons.Add(GoToNextProductButton);
					
				EndIf;
				
				Buttons.Add(FinishButton);
				
			ElsIf ThisIsLastCell
				And ThisIsLastItemInCell Then
				
				If ThisIsProcessingOrderOfItemCell Then
					QueryText = NStr("vi = 'Kết thúc 
						|điều chuyển hàng hóa?';
						|ru = 'Завершить 
						|перемещение товаров?';
						|en = 'Finish
						|transfer task?'; fa = 'Finish
						|transfer task?';
						|it = 'Terminare 
						| lo spostamento delle merci?';
						|pl = 'Zakończyć 
						|przenoszenie towarów?';
						|tr = 'Mal 
						|transferi tamamlansın mı?'");
				Else
					If Not ThereAreScannedItemsInCurCell Or ThisIsLastLineOfScan Then
						
						ReplacementParameters = New Structure;
						
						ReplacementParameters.Insert("OwnGoods", GoodsPresentation);
						ReplacementParameters.Insert("Cell",
							?(WebServiceMode, Form.CurrentScanningLine.CellCode, Form.CurrentScanningLine.Cell));
						ReplacementParameters.Insert("JobType", TaskTypePresentation);
						ReplacementParameters.Insert("ExecutionType", ExecutionType);
						
						QueryText = StringFunctionsClientServer.InsertParametersIntoString(
							NStr("vi = 'Hàng hóa""[OwnGoods]"" trong ô ""[Cell]"" là cuối cùng trong nhiệm vụ [JobType]. 
								|Kết thúc thực hiện nhiệm vụ?';
								|ru = 'Товар ""[OwnGoods]"" в ячейке ""[Cell]"" последний в задании на [JobType]. 
								|Завершить выполнение задания?';
								|en = '[OwnGoods] in storage bin [Cell] was the last item to process.
								|Do you want to finish the task: [JobType]?'; fa = '[OwnGoods] in storage bin [Cell] was the last item to process.
								|Do you want to finish the task: [JobType]?';
								|it = 'La merce ""[OwnGoods]"" nella cella ""[Cell]"" è l''ultima nel task di [JobType]. 
								| Completare il task?';
								|pl = 'Towar ""[OwnGoods]"" w komórce ""[Cell]"" jest ostatni w zadaniu na [JobType].
								|Zakończyć wykonanie zadania?';
								|tr = '""[Cell]"" hücresindeki ""[OwnGoods]"" öğesi, [JobType]''ndeki görevdeki son öğedir. 
								|Görev tamamlandı mı?'"),
							ReplacementParameters);
						
					Else
						QueryText = NStr("vi = 'Chưa kết thúc thực hiện nhiệm vụ 
							|xếp vào hàng hóa.';
							|ru = 'Выполнение задания по размещению товаров 
							|не закончено.';
							|en = 'Put-away task
							|is not completed.'; fa = 'Put-away task
							|is not completed.';
							|it = 'L''esecuzione del task di collocamento delle merci 
							| non è completata.';
							|pl = 'Wykonanie zadania na umieszczenie towarów 
							|nie zakończono.';
							|tr = 'Ürünlerin yerleştirilmesi 
							|görevi tamamlanmadı.'");
					EndIf;
				EndIf;
				
				Buttons.Add(ContinueButton);
				
				If Not ThisIsProcessingOrderOfItemCell Then
					If Not ThereAreScannedItemsInCurCell Then
						// It is not required to offer processing of the next product according to the warehouse task.
					ElsIf Not ThisIsLastLineOfScan Then
						Buttons.Add(GoToNextProductButton);
					EndIf;
				EndIf;
				
				Buttons.Add(FinishButton);
				
			EndIf;
			
		Else
			
			If Not ThisIsLastCell Then
				
				QueryText = NStr("vi = 'Chưa hoàn tất nhiệm vụ lấy ra hàng hóa.';
								|ru = 'Задание по отбору товаров не закончено.';
								|en = 'Picking job is not finished.'; fa = 'Picking job is not finished.';
								|it = 'Il task di selezione delle merci non è terminato.';
								|pl = 'Zadanie na wybór towarów nie zakończono.';
								|tr = 'Ürün filtre görevi tamamlanmadı.'");
				
				Buttons.Add(ContinueButton);
				Buttons.Add(GoToNextCellButton);
				
				If ThereIsScannedCell Then
					Buttons.Add(GoToNextProductButton);
				EndIf;
				
				If ThereAreScannedProducts Then
					Buttons.Add(GoToPlacementButton);
				EndIf;
				
				Buttons.Add(FinishButton);
				
			ElsIf Not ThisIsLastItemInCell Then
				
				QueryText = NStr("vi = 'Chưa kết thúc nhiệm vụ lấy ra.';
								|ru = 'Задания по отбору не закончено.';
								|en = 'Picking job not finished.'; fa = 'Picking job not finished.';
								|it = 'Il task di selezione non è terminato.';
								|pl = 'Zadanie na wybór nie zakończono.';
								|tr = 'Filtre görevleri tamamlanmadı.'");
				
				Buttons.Add(ContinueButton);
				
				If ThereIsScannedCell Then
					Buttons.Add(GoToNextProductButton);
				EndIf;
				
				If ThereAreScannedProducts Then
					Buttons.Add(GoToPlacementButton);
				EndIf;
				
				Buttons.Add(FinishButton);
				
			ElsIf ThisIsLastCell
				And ThisIsLastItemInCell Then
				
				If Not ThereAreScannedItemsInCurCell
					Or ThisIsLastLineOfScan Then
					
					ReplacementParameters = New Structure;
					
					ReplacementParameters.Insert("OwnGoods", GoodsPresentation);
					ReplacementParameters.Insert("Cell",
						?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
					ReplacementParameters.Insert("JobType", TaskTypePresentation);
					ReplacementParameters.Insert("CompleteSelection_",
						?(ThereAreScannedProducts,
							NStr("vi = 'Kết thúc lấy ra và chuyển 
								|sang xếp vào hàng hóa?';
								|ru = 'Завершить отбор и перейти 
								|к размещению товаров?';
								|en = 'Do you want to finish picking
								|and go to Put-away list?'; fa = 'Do you want to finish picking
								|and go to Put-away list?';
								|it = 'Terminare la selezione e passare 
								|al collocamento delle merci?';
								|pl = 'Zakończyć wybór i przejść 
								|do umieszczenia towarów?';
								|tr = 'Filtreyi tamamlayıp ürünlerin yerleştirilmesine 
								|geçilsin mi?'"),
							NStr("vi = 'Hoàn thành việc lựa chọn?';
								|ru = 'Завершить отбор?';
								|en = 'Finish picking job?'; fa = 'Finish picking job?';
								|it = 'Terminare la selezione?';
								|pl = 'Zakończyć wybór?';
								|tr = 'Filtre tamamlansın mı?'")));
					
					QueryText = StringFunctionsClientServer.InsertParametersIntoString(
						NStr("vi = 'Hàng hóa ""[OwnGoods]"" 
							|trong ô ""[Cell]"" 
							|là cuối cùng trong nhiệm vụ [JobType]. 
							|
							|[CompleteSelection_]';
							|ru = 'Товар ""[OwnGoods]"" 
							|в ячейке ""[Cell]"" 
							|последний в задании на [JobType]. 
							|
							|[CompleteSelection_]';
							|en = '[OwnGoods] in storage bin [Cell]
							|was the last item in the task:
							|[JobType].
							|
							|[CompleteSelection_]'; fa = '[OwnGoods] in storage bin [Cell]
							|was the last item in the task:
							|[JobType].
							|
							|[CompleteSelection_]';
							|it = 'La merce ""[OwnGoods]"" 
							|nella cella ""[Cell]"" 
							|è l''ultima nel task di [JobType]. 
							|
							|[CompleteSelection_]';
							|pl = 'Towar ""[OwnGoods]"" 
							|w komórce ""[Cell]"" 
							|jest ostatni w zadaniu na [JobType]. 
							|
							|[CompleteSelection_]';
							|tr = '""[OwnGoods]"" 
							|""[Cell]"" hücresindeki ürün 
							|, [JobType]''ndeki görevindeki son üründür. 
							|
							|[CompleteSelection_]'"), 
						ReplacementParameters);
					
				Else
					QueryText = NStr("vi = 'Chưa kết thúc nhiệm vụ lọc.';
									|ru = 'Задание по отбору не закончено.';
									|en = 'Picking is not finished.'; fa = 'Picking is not finished.';
									|it = 'Il task di selezione non è terminato.';
									|pl = 'Zadanie na wybór nie zakończono.';
									|tr = 'Filtre görevi bitmedi.'");
				EndIf;
				
				Buttons.Add(ContinueButton);
				
				If Not ThereAreScannedItemsInCurCell Then
					// It is not required to offer processing of the next product according to the warehouse task.
				ElsIf Not ThisIsLastLineOfScan Then
					Buttons.Add(GoToNextProductButton);
				EndIf;
				
				If ThereAreScannedProducts Then
					Buttons.Add(GoToPlacementButton);
				EndIf;
				
				Buttons.Add(FinishButton);
				
			EndIf;
			
		EndIf;
		
	ElsIf JobType = "PickingCheck" Then
		
		ContinueButton = NewDialogButton(
			"GoToThePreviousPage",
			NStr("vi = 'Tiếp tục 
				|kiểm tra lấy ra hàng hóa';
				|ru = 'Продолжить 
				|проверку отбора товаров';
				|en = 'Resume
				|follow-up check'; fa = 'Resume
				|follow-up check';
				|it = 'Continuare 
				| la verifica della selezione delle merci';
				|pl = 'Kontynuować 
				|weryfikację wyboru towarów';
				|tr = 'Ürün filtre 
				|kontrolüne devam et'"));
		
		GoToNextProductButton = NewDialogButton(
			"GoToTheNextScanningGoods",
			NStr("vi = 'Chuyển sang 
				|mặt hàng tiếp theo';
				|ru = 'Перейти 
				|к следующему товару';
				|en = 'Go to
				|next item'; fa = 'Go to
				|next item';
				|it = 'Passare 
				| alla merce successiva';
				|pl = 'Przejść 
				|do następnego towaru';
				|tr = 'Sonraki ürüne 
				|git'"));
		
		FinishButton = NewDialogButton(
			"FinishJobExecution",
			NStr("vi = 'Kết thúc 
				|kiểm tra lấy ra hàng hóa';
				|ru = 'Завершить 
				|проверку отбора товаров';
				|en = 'Finish
				|follow-up check'; fa = 'Finish
				|follow-up check';
				|it = 'Terminare 
				| la verifica della selezione delle merci';
				|pl = 'Zakończyć 
				|weryfikację wyboru towarów';
				|tr = 'Ürün filtre 
				|kontrolünü tamamla'"));
		
		QueryText = NStr("vi = 'Kết thúc 
			|kiểm tra lấy ra hàng hóa?';
			|ru = 'Завершить 
			|проверку отбора товаров?';
			|en = 'Finish
			|follow-up check?'; fa = 'Finish
			|follow-up check?';
			|it = 'Terminare 
			|la verifica della selezione delle merci?';
			|pl = 'Zakończyć 
			|weryfikację wyboru towarów?';
			|tr = 'Ürün filtre 
			|kontrolünü tamamla?'");
		
		Buttons.Add(ContinueButton);
		
		If Not ThisIsLastLineOfScan
			Or Not AllJobLinesAreScanned(Form) Then
			
			QueryText = NStr("vi = 'Chuyển sang 
				|mặt hàng tiếp theo?';
				|ru = 'Перейти 
				|к следующему товару?';
				|en = 'Go to
				|next item?'; fa = 'Go to
				|next item?';
				|it = 'Passare 
				| alla merce successiva?';
				|pl = 'Przejść 
				|do następnego towaru?';
				|tr = 'Sonraki ürüne 
				|git?'");
			Buttons.Add(GoToNextProductButton);
			
		EndIf;
		
		Buttons.Add(FinishButton);
		
	EndIf;
	
	ShowMessageDialog(Form, QueryText, Buttons);
	
EndProcedure

// Called when the get information button is clicked.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToGetInformation(Form) Export
	
	Form.InformationTable.Clear();
	Form.MarkTheBinForRecount = False;
	GoToPage3(Form,"RequestInformationPage");
	
EndProcedure

// Called when the button is pressed, mark the cell to be recalculated.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToCellMarkToRecalculate(Form) Export
	
	Form.InformationTable.Clear();
	Form.MarkTheBinForRecount = True;
	GoToPage3(Form,"RequestInformationPage");
	
EndProcedure

// Called from the wait handler in the warehouse worker's workplace form.
// Used to periodically update the list of available warehouse tasks.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** Jobs - FormTable - a table containing information about warehouse tasks.
//
Procedure UpdateListOfTasksWaitingHandler(Form) Export
	
	If Form.Items.FormPages.CurrentPage = Form.Items.OperationSelectionPage Then
		UpdateMainMenu(Form);
	ElsIf Form.Items.FormPages.CurrentPage = Form.Items.PageJobSelection Then
		Form.Items.Jobs.Refresh();
	EndIf;
	
EndProcedure

// Used when trying to close the warehouse worker's workplace form,
// using the close button or the Esc key.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure DoNotCloseMobileWorkplaceForm(Form) Export
	
	Form.ModeSettings.YouCanCloseForm = False;
	GoToWarehouseOperationSelection(Form);
	
EndProcedure

// Called when the close button is clicked on the get information page.
// Returns the workplace to the previous page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure InformationClose(Form) Export
	
	GoToThePreviousPage(Form);
	
EndProcedure

// Called from the event handler Before closing workplace forms.
//  It is necessary to prevent a situation when a warehouse task is taken into operation
//  and is not completed. You should either cancel it, or still execute it.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
// 	Cancel - Boolean - The truth is, if you do not want to close the form the workplace.
// 	StandardProcessing - Boolean - The truth is, if you are a standard, systematic treatment of the form is closed.
//
Procedure BeforeClose(Form, Cancel, StandardProcessing) Export
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	GoodsForScanning = Form.GoodsForScanning;
	YouCanCloseForm = Form.ModeSettings.YouCanCloseForm;
	CurrentPage = Form.Items.FormPages.CurrentPage;
	
	If Not YouCanCloseForm Then
		
		Cancel = True;
		StandardProcessing = False;
		
		If CurrentPage = Items.SelectValuePage Then
			
			SelectingTheCancelValue(Form);
			Return;
			
		ElsIf CurrentPage = Items.EnterQuantityPage Then
			
			EnteringAQuantityCancel(Form);
			Return;
			
		ElsIf CurrentPage = Items.ScanPage Then
			
			MessageText                = NStr("vi = 'Bây giờ không thể đóng chương trình - trước hết cần kết thúc nhiệm vụ hiện tại.';
												|ru = 'Сейчас нельзя закрыть программу - сначала нужно завершить текущее задание.';
												|en = 'Finish the current task before closing the application.'; fa = 'Finish the current task before closing the application.';
												|it = 'Non è possibile chiudere il programma adesso - è necessario terminare il task corrente.';
												|pl = 'Teraz nie można zamknąć programu -najpierw trzeba zakończyć bieżące zadanie.';
												|tr = 'Artık programı kapatılmamalı- önce mevcut görevin tamamlanması gerekir.'");
			ModeSettings.ClosingForm_ = True;
			
			Buttons = New ValueList;
			
			Buttons.Add(NewDialogButton("FinishJobExecution", NStr("vi = 'Kết thúc nhiệm vụ';
																	|ru = 'Завершить задание';
																	|en = 'Finish task'; fa = 'پایان وظیفه';
																	|it = 'Terminare il task';
																	|pl = 'Zakończyć zadanie';
																	|tr = 'Görevi tamamla'")));
			Buttons.Add(NewDialogButton("GoToScanning", NStr("vi = 'Quay lại thực hiện nhiệm vụ';
															|ru = 'Вернуться к выполнению задания';
															|en = 'Resume task'; fa = 'ازسرگیری وظیفه';
															|it = 'Ritorna all''esecuzione del task';
															|pl = 'Wróć do wykonania zadania';
															|tr = 'Görevin gerçekleştirilmesine geri dön'")));
			
			ShowMessageDialog(Form, MessageText, Buttons);
			
			Return;
			
		ElsIf CurrentPage = Items.RequestInformationPage Then
			
			If Form.MarkTheBinForRecount Then
				SelectingTheCancelValue(Form);
			EndIf;
			
			Return;
			
		ElsIf CurrentPage = Items.OperationSelectionPage Then
			MainMenuClose(Form);
			Return;
		ElsIf CurrentPage <> Items.OperationSelectionPage Then
			Return;
		EndIf;
		
	Else
		
		// Check the mode and the state of the mode from which they are trying to close the forms.
		If GoodsForScanning.Count() > 0 Then
			
			Cancel = True;
			StandardProcessing = False;
			
			MessageText = NStr("vi = 'Bây giờ không thể đóng chương trình - trước hết cần kết thúc nhiệm vụ hiện tại.';
								|ru = 'Сейчас нельзя закрыть программу - сначала нужно завершить текущее задание.';
								|en = 'Finish the current task before closing the application.'; fa = 'Finish the current task before closing the application.';
								|it = 'Non è possibile chiudere il programma adesso - è necessario terminare il task corrente.';
								|pl = 'Teraz nie można zamknąć programu -najpierw trzeba zakończyć bieżące zadanie.';
								|tr = 'Artık programı kapatılmamalı- önce mevcut görevin tamamlanması gerekir.'");
			
			Buttons = New ValueList;
			
			Buttons.Add(NewDialogButton("FinishJobExecution", NStr("vi = 'Kết thúc nhiệm vụ';
																	|ru = 'Завершить задание';
																	|en = 'Finish task'; fa = 'پایان وظیفه';
																	|it = 'Terminare il task';
																	|pl = 'Zakończyć zadanie';
																	|tr = 'Görevi tamamla'")));
			Buttons.Add(NewDialogButton("GoToScanning", NStr("vi = 'Quay lại thực hiện nhiệm vụ';
															|ru = 'Вернуться к выполнению задания';
															|en = 'Resume task'; fa = 'ازسرگیری وظیفه';
															|it = 'Ritorna all''esecuzione del task';
															|pl = 'Wróć do wykonania zadania';
															|tr = 'Görevin gerçekleştirilmesine geri dön'")));
			
			ShowMessageDialog(Form, MessageText, Buttons);
			
		Else
			
			MessageText = NStr("vi = 'Đóng chương trình?';
								|ru = 'Закрыть программу?';
								|en = 'Close the application?'; fa = 'Close the application?';
								|it = 'Chiudere il programma?';
								|pl = 'Zamknąć program?';
								|tr = 'Programı kapat?'");
			
			Buttons = New ValueList;
			
			Buttons.Add(NewDialogButton("CloseTheFormOfMobileWorkplace", NStr("vi = 'Đóng';
																				|ru = 'Закрыть';
																				|en = 'Close'; fa = 'بستن';
																				|it = 'Chiudere';
																				|pl = 'Zamknij';
																				|tr = 'Kapat'")));
			Buttons.Add(NewDialogButton("DoNotCloseMobileWorkplaceForm", NStr("vi = 'Không đóng';
																				|ru = 'Не закрывать';
																				|en = 'Do not close'; fa = 'بسته نشود';
																				|it = 'Non chiudere';
																				|pl = 'Nie zamykaj';
																				|tr = 'Kapatmayın'")));
			
			ShowMessageDialog(Form, MessageText, Buttons);
			
			ProductsServer.SaveSeriesScanModeSetting(Form);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Called when the close button is clicked on the main processing page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure MainMenuClose(Form) Export
	
	QueryText = NStr("vi = 'Đóng chương trình?';
					|ru = 'Закрыть программу?';
					|en = 'Close the application?'; fa = 'Close the application?';
					|it = 'Chiudere il programma?';
					|pl = 'Zamknąć program?';
					|tr = 'Programı kapat?'");
	
	CloseButton = NewDialogButton("CloseTheFormOfMobileWorkplace", NStr("vi = 'Đóng';
																		|ru = 'Закрыть';
																		|en = 'Close'; fa = 'بستن';
																		|it = 'Chiudere';
																		|pl = 'Zamknij';
																		|tr = 'Kapat'"), True);
	DonTCloseButton = NewDialogButton("DoNotCloseMobileWorkplaceForm", NStr("vi = 'Không đóng';
																			|ru = 'Не закрывать';
																			|en = 'Do not close'; fa = 'بسته نشود';
																			|it = 'Non chiudere';
																			|pl = 'Nie zamykaj';
																			|tr = 'Kapatmayın'"));
	
	Buttons = New ValueList;
	
	Buttons.Add(CloseButton);
	Buttons.Add(DonTCloseButton);
	
	ShowMessageDialog(Form, QueryText, Buttons);
	
EndProcedure

// Switches to the message output page, displays the message text, and displays a list of
// available response options.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** CaptionMessageText - FormField - information label for the user interface.
//	MessageText - String - text of the question or message.
//	Buttons - ValueList, Structure - a list of buttons or a single button.
//	MessageTitle - String - the text that will be set in the form header.
//	DisplayTableOfInformation - Boolean - if a value is specified, the table is displayed.
//
Procedure ShowMessageDialog(Form, MessageText, Buttons, MessageTitle = "", DisplayTableOfInformation = False) Export
	
	GetUserMessages(True);
	
	Items = Form.Items;
	
	Items.CaptionMessageText.Title = MessageText;
	Items.MessageInformationTable.Visible = DisplayTableOfInformation;
	
	// Delete existing action buttons.
	IndexBoundary = Items.ActionTeamGroup.ChildItems.Count() - 1;
	
	For CurIndex__ = 0 To IndexBoundary Do
		
		OBRIndex = IndexBoundary - CurIndex__;
		Item = Items.ActionTeamGroup.ChildItems[OBRIndex];
		
		Items.Delete(Item);
		
	EndDo;
	
	// Add action buttons.
	If TypeOf(Buttons) = Type("ValueList") Then
		
		// First you need to go through the list of buttons and check
		// if there should be at least one "highlighted" button. And there should not be more than one such button.
		// If there is not a single "highlighted" button, then you need to select at least one.
		// The highlighted button should be the first one on top.
		
		NumberOfAllocated = 0;
		
		For Each ListItem In Buttons Do
			
			Button = ListItem.Value;
			
			If Button.Select_ Then
				NumberOfAllocated = NumberOfAllocated + 1;
				If NumberOfAllocated = 1 Then
					Continue;
				Else
					Button.Select_ = False; // reset the selection flag for an "unnecessarily" highlighted button
				EndIf;
			EndIf;
			
		EndDo;
		
		// ... if there are no dedicated buttons, then select at least one.
		If NumberOfAllocated = 0 And (Buttons.Count() > 1) Then
			Buttons[0].Value.Select_ = True;
		EndIf;
		
		// ... check that the highlighted button is on top.
		HighlightedButton = Undefined;
		
		For Each ListItem In Buttons Do
			If ListItem.Value.Select_ Then
				HighlightedButton = ListItem;
			EndIf;
		EndDo;
		
		If Not (HighlightedButton = Undefined) Then
			Buttons.Delete(HighlightedButton);
			Buttons.Insert(0, HighlightedButton.Value);
		EndIf;
		
		// Display buttons in the message dialog.
		For Each ListItem In Buttons Do
			AddMessageDialogButton(Form, ListItem.Value);
		EndDo;
		
	ElsIf TypeOf(Buttons) = Type("Structure") Then
		
		AddMessageDialogButton(Form, Buttons);
		
	EndIf;
	
	SetFormHeader(Form, MessageTitle);
	GoToPage3(Form, "MessagePage");
	
EndProcedure

// The procedure to set the headers of the elements of the scan. Called
// when switching to another line, product, or scan cell.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace
//
Procedure SetScanItemHeaders(Form) Export
	
	SetCellTitle(Form);
	SetProductTitle(Form);
	SetDestinationHeader(Form);
	SetSeriesTitle(Form);
	SetQuantityHeader(Form);
	SetQuantityHeaderInDocument(Form);
	SetQuantityHeaderDoNotShip(Form);
	
EndProcedure

// The procedure sets the text of the form header depending on 
// which scanning element is active.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetFormHeaderOfScanItems(Form) Export
	
	Mode = Form.ModeSettings.Mode;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	ScanParameter = Form.ModeSettings.ScanParameter;
	
	If Mode = "ActionChoice" Then
		Return;
	EndIf;
	
	If ScanParameter = "Cell" Then
		If ThisIsSetOfGoods Then
			TitleText = CaptionTextOfFormElementTitle("HintScanSCOfAcceptanceZone", Form);
		Else
			TitleText = CaptionTextOfFormElementTitle("HintScanWKCells", Form);
		EndIf;
	ElsIf JobType = "Receiving"
		And (ScanParameter = "Products" 
			Or ScanParameter = "Count")
		And Form.UsePackingLists Then
		
		TitleText = CaptionTextOfFormElementTitle("HintScanInventoryArea", Form);
		
	ElsIf ScanParameter = "Products" 
			Or ScanParameter = "Count" Then
		
		TitleText = CaptionTextOfFormElementTitle("HintScanProductProfile", Form);
		
	ElsIf ScanParameter = "Series" Then
		TitleText = CaptionTextOfFormElementTitle("HintScanSHKSeries", Form);
	EndIf;
	
	SetFormHeader(Form, TitleText);
	
EndProcedure

// Calls procedures for setting properties of parameters-scan elements:
// product, series, cell.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetParametersForScanItems(Form) Export
	
	SetFormHeaderOfScanItems(Form);
	SetScanItemHeaders(Form);
	SetIlluminationOfScanningElements(Form);
	SetAvailabilityOfScanItems(Form);
	SetColorsOfScanItems(Form);
	
EndProcedure

// Calls separate procedures for setting the availability of items on the scan page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetAvailabilityOfScanItems(Form) Export
	
	SetQuantityInputAvailability(Form);
	SetSeriesAvailability(Form);
	SetDestinationAvailability(Form);
	
EndProcedure

// Called from event handlers for the creation of the workplace forms server.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** ScanSeries - FormButton - a button that opens information about the product series.
// 	Cancel - Boolean - The truth is, if you do not want to close the form the workplace.
// 	StandardProcessing - Boolean - The truth is, if you are a standard, systematic treatment of the form is closed.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	SetConditionalAppearance(Form);
	
	TMCommonUse.CustomizePeripherals(Form);
	
	Form.InterfaceVersion82 = Version8_2OfClientApplicationInterface(InfoBaseUsers.CurrentUser().Name);
	
	Parameters = Form.Parameters;
	
	SetSettingsForScreenResolution(Form);
	
	// Get the values of the passed parameters.
	Form.Object.Warehouse = Parameters.Warehouse;
	Form.Object.Premise = Parameters.Premise;
	Form.Object.User = Users.CurrentUser();
	
	If Parameters.Property("WebServiceMode") Then
		
		Form.Password = Parameters.Password;
		Form.UserName = Parameters.UserName;
		Form.WebServiceMode = Parameters.WebServiceMode;
		Form.Object.User = Parameters.User;
		Form.WSDLLocation = Parameters.WSDLLocation;
		
	EndIf;
	
	If Parameters.Property("WarehouseJobProcessingProcedure") Then
		Form.Object.WarehouseJobProcessingProcedure = Parameters.WarehouseJobProcessingProcedure;
	Else
		Form.Object.WarehouseJobProcessingProcedure = Enums.WarehouseJobProcessingProcedure.StorageBinGoods;
	EndIf;
	
	Form.Warehouse = Form.Object.Warehouse;
	Form.Premise = Form.Object.Premise;
	Form.User = Form.Object.User;
	Form.WarehouseJobProcessingProcedure = Form.Object.WarehouseJobProcessingProcedure;
	
	// Get the values of FO and constants.
	Form.UsePackingLists = GetFunctionalOption("UsePackingLists");
	Form.UseReusablePackage = GetFunctionalOption("UseReusablePackage");
	Form.DeliveryManagementIsUsed = GetFunctionalOption("UseDeliveryManagement");
	Form.BinLocationWarehousingIsUsed = WarehousesServer.UseBinLocationWarehousing(Parameters.Warehouse, Parameters.Premise, ,
		False);
	
	Form.Object.UseOrderSupplyWithAssignment = GetFunctionalOption(
		"UseOrderSupplyWithAssignment");
	Form.UseItemsBatch = ?(Form.WebServiceMode, True,
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure("Warehouse", Parameters.Warehouse)));
	
	Form.UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	Form.UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	Form.IsFullUser = Users.IsFullUser(, , False);
	
	Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	// Download the data of labels and headings from the layout of the "Texts of Headings".
	UploadCaptionTextsForFormHeaders(Form);
	
	// Set the availability of form elements.
	Form.Items.ScanSeries.Enabled = Form.UseItemsBatch;
	
	// Set the scan scheme settings.
	SetParametersOfScanSchemeElements(Form);
	SetParametersForItemsInWarehouseTaskProcessingOrder(Form);
	InitializeModeParameters(Form);
	
	// Set the task list display settings.
	Form.DisplayAllJobs = True;
	
	FillInShipmentAcceptanceZones(Form);
	
	// Set the form title text.
	FormTitleText = CaptionTextOfFormElementTitle("HeaderSelects", Form);
	
	SetFormHeader(Form, FormTitleText);
	GoToWarehouseOperationSelection(Form);
	
	WhenNavigatingToPage(Form, "OperationSelectionPage");
	SetHotkeysOnCurPage(Form);
	ProductsServer.LoadSeriesScanModeSetting(Form);
	
EndProcedure

// Switches the workspace to the main menu in the selection mode storage operations.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToWarehouseOperationSelection(Form) Export
	
	Form.ModeSettings.JobType = "";
	UpdateMainMenu(Form);
	GoToPage3(Form, "OperationSelectionPage");
	
EndProcedure

// Switches the workplace to the destination selection list.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToDestinationSelection(Form) Export
	
	FormTitleText = CaptionTextOfFormElementTitle("DestinationSelectionHeader", Form);
	
	// Set the headers of the elements.
	SetFormHeader(Form, FormTitleText);
	
	If Form.ModeSettings.JobType = "Recalculate"
		Or Form.ModeSettings.JobType = "PickingCheck" Then
		
		Form.Items.AssignmentsBalance.Visible = False;
		
	Else
		Form.Items.AssignmentsBalance.Visible = True;
	EndIf;
	
	Form.Object.Assignments.Load(Assignments(Form));
	Form.Object.Assignments.Insert(0); // A string without an assignment
	
	GoToPage3(Form, "SelectDestinationPage");
	
EndProcedure

#EndRegion

#Region Private

// Adds the text label of an item in a table of the texts of the labels of the elements.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* HeaderLabelTexts - FormDataCollection - a table containing the headers of form elements.
//	LabelID - String - the ID of the label.
//
Procedure AddElementCaptionText(Form, LabelID)

	ScreenResolution = Form.ScreenResolution;
	Resolution240x320 = Enums.ScreenResolutions.Resolution240x320;
	Resolution320x320 = Enums.ScreenResolutions.Resolution320x320;
	
	If LabelID = "TitleAllSelectionTasks" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Tất cả nhiệm vụ lấy ra';
							|ru = 'Все задания на отбор';
							|en = 'All picking jobs'; fa = 'All picking jobs';
							|it = 'Tutti i task di selezione';
							|pl = 'Wszystkie zadania na wybór';
							|tr = 'Tüm filtre görevleri'");
		Else
			LabelText = NStr("vi = 'Tất cả nhiệm vụ lấy ra';
							|ru = 'Все з-ния на отбор';
							|en = 'All p-ng jobs'; fa = 'All p-ng jobs';
							|it = 'Tutti i task di selezione';
							|pl = 'Wszystkie zadania na wybór';
							|tr = 'Tüm filtre görevleri'");
		EndIf;
	ElsIf LabelID = "TitleMySelectionTasks" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Nhiệm vụ lấy ra của tôi';
							|ru = 'Мои задания на отбор';
							|en = 'My picking jobs'; fa = 'My picking jobs';
							|it = 'I miei task di selezione';
							|pl = 'Moje zadania na wybór';
							|tr = 'Benim filtre için görevlerim'");
		Else
			LabelText = NStr("vi = 'Nhiệm vụ lấy ra của tôi';
							|ru = 'Мои з-ния на отбор';
							|en = 'My p-ng jobs'; fa = 'My p-ng jobs';
							|it = 'I miei task di selezione';
							|pl = 'Moje zadania na wybór';
							|tr = 'Benim filtre için görevlerim'");
		EndIf;
	ElsIf LabelID = "TitleAllPlacementTasks" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Tất cả nhiệm vụ sắp xếp';
							|ru = 'Все задания на размещение';
							|en = 'All put-away tasks'; fa = 'All put-away tasks';
							|it = 'Tutti i task di collocamento';
							|pl = 'Wszystkie zadania na umieszczenie';
							|tr = 'Tüm yerleştirme görevleri'");
		Else
			LabelText = NStr("vi = 'Tất cả các vị trí';
							|ru = 'Все размещения';
							|en = 'All put-aways'; fa = 'All put-aways';
							|it = 'Tutti i collocamenti';
							|pl = 'Wszystkie umieszczenia';
							|tr = 'Tüm yerleştirmeler'");
		EndIf;
	ElsIf LabelID = "TitleMyPlacementTasks" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Nhiệm vụ sắp xếp của tôi';
							|ru = 'Мои задания на размещение';
							|en = 'My put-away tasks'; fa = 'My put-away tasks';
							|it = 'I miei task di collocamento';
							|pl = 'Moje zadania na umieszczenie';
							|tr = 'Benim yerleştirme görevlerim'");
		Else
			LabelText = NStr("vi = 'Nhiệm vụ sắp xếp của tôi.';
							|ru = 'Мои з-ния на размещ.';
							|en = 'My put-aways'; fa = 'My put-aways';
							|it = 'I miei task di collocamento.';
							|pl = 'Moje zadania na umieszczenie.';
							|tr = 'Benim yerleştirme görevlerim'");
		EndIf;
	ElsIf LabelID = "TitleAllMovingTasks" Then
		If (ScreenResolution = Resolution240x320)
			Or (ScreenResolution = Resolution320x320) Then
			LabelText = NStr("vi = 'Tất cả các lưu chuyển';
							|ru = 'Все перемещения';
							|en = 'All transfers'; fa = 'All transfers';
							|it = 'Tutti i spostamenti';
							|pl = 'Wszystkie przenoszenia';
							|tr = 'Tüm transferler'");
		Else
			LabelText = NStr("vi = 'Tất cả nhiệm vụ điều chuyển';
							|ru = 'Все задания на перемещение';
							|en = 'All transfer tasks'; fa = 'All transfer tasks';
							|it = 'Tutti i task di spostamento';
							|pl = 'Wszystkie zadania na przenoszenie';
							|tr = 'Tüm transfer görevleri'");
		EndIf;
	ElsIf LabelID = "HeadingMyMovingTasks" Then
		If (ScreenResolution = Resolution240x320)
			Or (ScreenResolution = Resolution320x320) Then
			LabelText = NStr("vi = 'Nhiệm vụ điều chuyển của tôi';
							|ru = 'Мои з-ния на п-щение';
							|en = 'My transfers'; fa = 'My transfers';
							|it = 'I miei task di spostamento';
							|pl = 'Moje zadania na przenoszenie';
							|tr = 'Benim transfer görevlerim'");
		Else
			LabelText = NStr("vi = 'Nhiệm vụ điều chuyển của tôi';
							|ru = 'Мои задания на перемещение';
							|en = 'My transfer tasks'; fa = 'My transfer tasks';
							|it = 'I miei task di spostamento';
							|pl = 'Moje zadania na przenoszenie';
							|tr = 'Benim transfer görevlerim'");
		EndIf;
	ElsIf LabelID = "TitleAllRecalculationTasks" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Tất cả nhiệm vụ kiểm đếm';
							|ru = 'Все задания на пересчет';
							|en = 'All inventory counts'; fa = 'All inventory counts';
							|it = 'Tutti i task di ricalcolo';
							|pl = 'Wszystkie zadania na przeliczanie';
							|tr = 'Tüm yeniden hesaplama görevleri'");
		Else
			LabelText = NStr("vi = 'Tất cả nhiệm vụ kiểm đếm';
							|ru = 'Все з-ния на п-счет';
							|en = 'All inv-y counts'; fa = 'All inv-y counts';
							|it = 'Tutti i task di ricalcolo';
							|pl = 'Wszystkie zadania na przeliczanie';
							|tr = 'Tüm yeniden hesaplama görevleri'");
		EndIf;
	ElsIf LabelID = "TitleMyRecalculationTasks" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Nhiệm vụ kiểm đếm của tôi';
							|ru = 'Мои задания на пересчет';
							|en = 'My inventory counts'; fa = 'My inventory counts';
							|it = 'I miei task di ricalcolo';
							|pl = 'Moje zadania na przeliczanie';
							|tr = 'Tüm yeniden hesaplama görevlerim'");
		Else
			LabelText = NStr("vi = 'Nhiệm vụ kiểm đếm của tôi';
							|ru = 'Мои з-ния на п-счет';
							|en = 'My inv-y counts'; fa = 'My inv-y counts';
							|it = 'I miei task di ricalcolo';
							|pl = 'Zadania na przeliczanie';
							|tr = 'Tüm yeniden hesaplama görevlerim'");
		EndIf;
	ElsIf LabelID = "TitleAllTasksForAcceptance" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Tất cả nhiệm vụ nhập hàng';
							|ru = 'Все задания на приемку';
							|en = 'All goods receipt tasks'; fa = 'All goods receipt tasks';
							|it = 'Tutti i task di accettazione';
							|pl = 'Wszystkie zadania na odbiór';
							|tr = 'Kabul için tüm görevler'");
		Else
			LabelText = NStr("vi = 'Tất cả nhiệm vụ nhập hàng';
							|ru = 'Все з-ния на п-мку';
							|en = 'All goods receipts'; fa = 'All goods receipts';
							|it = 'Tutti i task di accettazione';
							|pl = 'Wszystkie zadania na odbiór';
							|tr = 'Kabul için tüm görevler'");
		EndIf;
	ElsIf LabelID = "TitleMyAcceptanceTasks" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Nhiệm vụ tiếp nhận của tôi';
							|ru = 'Мои задания на приемку';
							|en = 'My goods receipt tasks'; fa = 'My goods receipt tasks';
							|it = 'I miei task di accettazione';
							|pl = 'Moje zadania na odbiór';
							|tr = 'Kabul için tüm görevlerlerim'");
		Else
			LabelText = NStr("vi = 'Nhiệm vụ tiếp nhận của tôi';
							|ru = 'Мои з-ния на п-мку';
							|en = 'My goods receipts'; fa = 'My goods receipts';
							|it = 'I miei task di accettazione';
							|pl = 'Moje zadania na odbiór';
							|tr = 'Kabul için tüm görevlerlerim'");
		EndIf;
	ElsIf LabelID = "TitleAllTasksForReview" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Tất cả nhiệm vụ kiểm tra';
							|ru = 'Все задания на проверку';
							|en = 'All follow-up checks'; fa = 'All follow-up checks';
							|it = 'Tutti i task di verifica';
							|pl = 'Wszystkie zadania na weryfikację';
							|tr = 'Kontrol için tüm görevlerler'");
		Else
			LabelText = NStr("vi = 'Tất cả nhiệm vụ kiểm tra';
							|ru = 'Все з-ния на п-рку';
							|en = 'All follow-ups'; fa = 'All follow-ups';
							|it = 'Tutti i task di verifica';
							|pl = 'Wszystkie zadania na weryfikację';
							|tr = 'Kontrol için tüm görevlerler'");
		EndIf;
	ElsIf LabelID = "TitleMyVerificationTasks" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Nhiệm vụ tiếp kiểm tra của tôi';
							|ru = 'Мои задания на проверку';
							|en = 'My follow-up checks'; fa = 'My follow-up checks';
							|it = 'I miei task di verifica';
							|pl = 'Moje zadania na weryfikację';
							|tr = 'Kontrol için tüm görevlerlerim'");
		Else
			LabelText = NStr("vi = 'Nhiệm vụ tiếp kiểm soát của tôi';
							|ru = 'Мои з-ния на п-рку';
							|en = 'My follow-ups'; fa = 'My follow-ups';
							|it = 'I miei task di verifica';
							|pl = 'Moje zadania na weryfikację';
							|tr = 'Kontrol için tüm görevlerlerim'");
		EndIf;
	ElsIf LabelID = "WrongCellError" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: đã quét không phải ô hàng.';
							|ru = 'Ошибка: отсканирована не та ячейка.';
							|en = 'Error: wrong bin is scanned.'; fa = 'Error: wrong bin is scanned.';
							|it = 'Errore: scansionata la cella sbagliata.';
							|pl = 'Błąd: została zeskanowana nie ta komórka.';
							|tr = 'Hata: yanlış hücre tarandı.'");
		Else
			LabelText = NStr("vi = 'Lỗi: đã quét không phải ô hàng.';
							|ru = 'Ошибка: отск. не та ячейка.';
							|en = 'Err: wrong bin is scanned.'; fa = 'Err: wrong bin is scanned.';
							|it = 'Errore: scansionata la cella sbagliata.';
							|pl = 'Błąd: została zeskanowana nie ta komórka.';
							|tr = 'Hata: yanlış hücre tarandı.'");
		EndIf;
	ElsIf LabelID = "ErrorWrongProduct" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: đã quét không phải hàng hóa.';
							|ru = 'Ошибка: отсканирован не тот товар.';
							|en = 'Error: wrong item is scanned.'; fa = 'Error: wrong item is scanned.';
							|it = 'Errore: scansionata la merce sbagliata.';
							|pl = 'Błąd: został zeskanowany nie ten towar.';
							|tr = 'Hata: yanlış ürün tarandı.'");
		Else
			LabelText = NStr("vi = 'Lỗi: đã quét không phải hàng hóa.';
							|ru = 'Ошибка: отск. не тот товар.';
							|en = 'Err: wrong item is scanned.'; fa = 'Err: wrong item is scanned.';
							|it = 'Errore: scansionata la merce sbagliata.';
							|pl = 'Błąd: został zeskanowany nie ten towar.';
							|tr = 'Hata: yanlış ürün tarandı.'");
		EndIf;
	ElsIf LabelID = "ErrorProductNotFound" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: mã vạch không chính xác.';
							|ru = 'Ошибка: неизвестный штрихкод.';
							|en = 'Error: unknown barcode.'; fa = 'Error: unknown barcode.';
							|it = 'Errore: codice a barre sconosciuto.';
							|pl = 'Błąd: nieznany kod kreskowy.';
							|tr = 'Hata: bilinmeyen barkod.'");
		Else
			LabelText = NStr("vi = 'Lỗi: mã vạch không chính xác.';
							|ru = 'Ошибка: неизвестный ШК.';
							|en = 'Err: unknown barcode.'; fa = 'Err: unknown barcode.';
							|it = 'Errore: codice a barre sconosciuto.';
							|pl = 'Błąd: nieznany KK.';
							|tr = 'Hata: bilinmeyen BK.'");
		EndIf;
	ElsIf LabelID = "WarningUnknownBarcode" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Mã vạch không xác định';
							|ru = 'Неизвестный штрихкод.';
							|en = 'Unknown barcode.'; fa = 'Unknown barcode.';
							|it = 'Codice a barre sconosciuto.';
							|pl = 'Nieznany kod kreskowy.';
							|tr = 'Bilinmeyen barkod.'");
		Else
			LabelText = NStr("vi = 'Mã vạch không xác định.';
							|ru = 'Неизвестный ШК.';
							|en = 'Unknown BC.'; fa = 'Unknown BC.';
							|it = 'Codice a barre sconosciuto.';
							|pl = 'Nieznany KK.';
							|tr = 'Bilinmeyen BK.'");
		EndIf;
	ElsIf LabelID = "ErrorUpSheetContainsPreviouslyScannedUpSheets" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: không thể thêm phiếu đóng gói này.';
							|ru = 'Ошибка: нельзя добавить этот уп. лист.';
							|en = 'Error: cannot add this packing list.'; fa = 'Error: cannot add this packing list.';
							|it = 'Errore: non è possibile aagiungere questa distinta di imallaggio.';
							|pl = 'Błąd: nie możesz dodać tego pakietu zarz. arkusz.';
							|tr = 'Hata: bu ürün listesi eklenemez.'");
		Else
			LabelText = NStr("vi = 'Lỗi: không thể thêm phiếu đóng gói này.';
							|ru = 'Ошибка: нельзя добавить этот уп. лист.';
							|en = 'Error: cannot add this packing list.'; fa = 'Error: cannot add this packing list.';
							|it = 'Errore: non è possibile aagiungere questa distinta di imallaggio.';
							|pl = 'Błąd: nie możesz dodać tego pakietu zarz. arkusz.';
							|tr = 'Hata: bu ürün listesi eklenemez.'");
		EndIf;
	ElsIf LabelID = "ErrorIsNotLinked" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: trong mã vạch chưa chỉ ra đóng gói.';
							|ru = 'Ошибка: у штрихкода не указана упаковка.';
							|en = 'Error: packaging unit for this barcode not specified.'; fa = 'Error: packaging unit for this barcode not specified.';
							|it = 'Errore: l''imballaggio non è indicato nel codice a barre.';
							|pl = 'Błąd: dla kodu kreskowego nie podano opakowanie.';
							|tr = 'Hata: barkodun, paketleme ünitesi belirtilmedi.'");
		Else
			LabelText = NStr("vi = 'Lỗi: trong mã vạch chưa chỉ ra đóng gói.';
							|ru = 'Ошибка: у ШК не указана упак.';
							|en = 'Error: packaging unit for this BC not specified.'; fa = 'Error: packaging unit for this BC not specified.';
							|it = 'Errore: l''imballaggio non è indicato nel codice a barre.';
							|pl = 'Błąd: dla KK nie podano opakowanie.';
							|tr = 'Hata: BK''nin bir paketleme ünitesi yok.'");
		EndIf;
	ElsIf LabelID = "ErrorIsWrongSeries" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: đã quét không phải sê-ri.';
							|ru = 'Ошибка: отсканирована не та серия.';
							|en = 'Error: wrong batch is scanned.'; fa = 'Error: wrong batch is scanned.';
							|it = 'Errore: scannerizzata la serie sbagliata.';
							|pl = 'Błąd: została zeskanowana nie ta seria.';
							|tr = 'Hata: yanlış parti tarandı.'");
		Else
			LabelText = NStr("vi = 'Lỗi: đã quét không phải sê-ri.';
							|ru = 'Ошибка: отск. не та серия.';
							|en = 'Err: wrong batch is scanned.'; fa = 'Err: wrong batch is scanned.';
							|it = 'Errore: scansionata la serie sbagliata.';
							|pl = 'Błąd: została zeskanowana nie ta seria.';
							|tr = 'Hata: yanlış parti tarandı.'");
		EndIf;
	ElsIf LabelID = "ErrorSeriesIsNotUnique" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: loạt sản phẩm không phải là duy nhất.';
							|ru = 'Ошибка: серия товара не уникальна.';
							|en = 'Error: batch is not unique.'; fa = 'Error: batch is not unique.';
							|it = 'Errore: la serie della merce non è univoca.';
							|pl = 'Błąd: seria towaru nie jest unikalna.';
							|tr = 'Hata: ürün partisi benzersiz değil.'");
		Else
			LabelText = NStr("vi = 'Lỗi: loạt không phải là duy nhất.';
							|ru = 'Ошибка: серия не уникальна.';
							|en = 'Err: batch is not unique.'; fa = 'Err: batch is not unique.';
							|it = 'Errore: serie non univoca.';
							|pl = 'Błąd: seria nie jest unikalna.';
							|tr = 'Hata: parti benzersiz değil.'");
		EndIf;
	ElsIf LabelID = "ErrorIncorrectQuantity" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: sai số lượng.';
							|ru = 'Ошибка: неверное количество.';
							|en = 'Error: invalid quantity.'; fa = 'Error: invalid quantity.';
							|it = 'Errore: quantità sbagliata.';
							|pl = 'Błąd: niepoprawna ilość.';
							|tr = 'Hata: yanlış miktar.'");
		Else
			LabelText = NStr("vi = 'Lỗi: sai số lượng.';
							|ru = 'Ошибка: неверное кол-во.';
							|en = 'Err: invalid quantity.'; fa = 'Err: invalid quantity.';
							|it = 'Errore: quantità sbagliata.';
							|pl = 'Błąd: niepoprawna ilość.';
							|tr = 'Hata: yanlış miktar.'");
		EndIf;
	ElsIf LabelID = "ErrorQuantityGreaterThanRequired" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: số lượng nhiều hơn yêu cầu.';
							|ru = 'Ошибка: количество больше требуемого.';
							|en = 'Error: actual quantity exceeds required quantity.'; fa = 'Error: actual quantity exceeds required quantity.';
							|it = 'Errore: quantità superiore alla richiesta.';
							|pl = 'Błąd: ilość jest większa od należnej.';
							|tr = 'Hata: gereğinden fazla miktar.'");
		Else
			LabelText = NStr("vi = 'Lỗi: số lượng lớn hơn số yêu cầu.';
							|ru = 'Ошибка: кол-во больше треб.';
							|en = 'Err: actual quantity exceeds required quantity.'; fa = 'Err: actual quantity exceeds required quantity.';
							|it = 'Errore: quantità superiore alla richiesta.';
							|pl = 'Błąd: ilość jest większa od należnej.';
							|tr = 'Hata: gereğinden fazla miktar.'");
		EndIf;
	ElsIf LabelID = "WarningProductMissingFromTask" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hàng hóa không có trong nhiệm vụ, hãy để lại.';
							|ru = 'Товара нет в задании, отложите товар.';
							|en = 'This item is not in the list. Please put it aside.'; fa = 'This item is not in the list. Please put it aside.';
							|it = 'La merce non è presente nel task, rimuovete la merce.';
							|pl = 'Towaru nie ma w zadaniu, odstaw towar.';
							|tr = 'Görevde ürün mevcut değil, ürünü ertele.'");
		Else
			LabelText = NStr("vi = 'Hàng hóa không có trong nhiệm vụ, hãy để lại.';
							|ru = 'Товара нет в зад., отл. товар.';
							|en = 'This item is not in the list. Pls put it aside.'; fa = 'This item is not in the list. Pls put it aside.';
							|it = 'La merce non è presente nel task, rimuovete la merce.';
							|pl = 'Towaru nie ma w zadaniu, odstaw towar.';
							|tr = 'Görevde ürün mevcut değil, ürünü ertele.'");
		EndIf;
	ElsIf LabelID = "WarningProductSelectedOverorder" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Đã chọn hàng thừa, hãy để lại.';
							|ru = 'Отобран лишний, отложите товар.';
							|en = 'This item is not required. Please put it aside.'; fa = 'This item is not required. Please put it aside.';
							|it = 'Selezionata in eccesso, rimuovete la merce.';
							|pl = 'Wybrany zbędny, odstaw towar.';
							|tr = 'Ekstra seçildi, ürünleri ertele.'");
		Else
			LabelText = NStr("vi = 'Đã chọn hàng thừa, hãy để lại.';
							|ru = 'Отобран лишний, отложите товар.';
							|en = 'This item is not required. Please put it aside.'; fa = 'This item is not required. Please put it aside.';
							|it = 'Selezionata in eccesso, rimuovete la merce.';
							|pl = 'Wybrany zbędny, odstaw towar.';
							|tr = 'Ekstra seçildi, ürünleri ertele.'");
		EndIf;
	ElsIf LabelID = "HeaderSelects" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hãy chọn giao dịch';
							|ru = 'Выберите операцию';
							|en = 'Select task'; fa = 'Select task';
							|it = 'Selezionate l''operazione';
							|pl = 'Wybierz czynność';
							|tr = 'İşlemi seç'");
		Else
			LabelText = NStr("vi = 'Chọn giao dịch';
							|ru = 'Выб. операцию';
							|en = 'S-ct task'; fa = 'S-ct task';
							|it = 'Selezionate l''operazione';
							|pl = 'Wybierz czynność';
							|tr = 'İşlemi seç'");
		EndIf;
	ElsIf LabelID = "HintScanSCOfAcceptanceZone" Then
		If (ScreenResolution = Resolution240x320)
			Or (ScreenResolution = Resolution320x320)Then
			LabelText = NStr("vi = 'Quét mã vạch khu vực tiếp nhận';
							|ru = 'Отск. ШК зоны приемки';
							|en = 'Scan inbound area BC'; fa = 'Scan inbound area BC';
							|it = 'Scansionate il codice a barre dell''area di accettazione';
							|pl = 'Zeskanuj KK strefy odbioru';
							|tr = 'Boşaltma alanı BK tara'");
		Else
			LabelText = NStr("vi = 'Hãy quét mã vạch khu vực nhập hàng';
							|ru = 'Отсканируйте ШК зоны приемки';
							|en = 'Scan inbound area barcode'; fa = 'Scan inbound area barcode';
							|it = 'Scansionate il codice a barre dell''area di accettazione';
							|pl = 'Zeskanuj KK strefy odbioru';
							|tr = 'Boşaltma alanı BK tara'");
		EndIf;
	ElsIf LabelID = "HintScanWKCells" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hãy quét mã vạch ô hàng';
							|ru = 'Отсканируйте ШК ячейки';
							|en = 'Scan storage bin barcode'; fa = 'Scan storage bin barcode';
							|it = 'Scansionate il codice a barre della cella';
							|pl = 'Zeskanuj KK komórki';
							|tr = 'Hücre BK tara'");
		Else
			LabelText = NStr("vi = 'Quét mã vạch ô hàng';
							|ru = 'Отск. ШК ячейки';
							|en = 'Scan storage bin BC'; fa = 'Scan storage bin BC';
							|it = 'Scansionate il codice a barre della cella';
							|pl = 'Zeskanuj KK komórki';
							|tr = 'Hücre BK tara'");
		EndIf;
	ElsIf LabelID = "HintScanProductProfile" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hãy quét mã vạch hàng hóa';
							|ru = 'Отсканируйте ШК товара';
							|en = 'Scan item barcode'; fa = 'Scan item barcode';
							|it = 'Scansionate il codice a barre della merce';
							|pl = 'Zeskanuj KK towaru';
							|tr = 'Ürün BK tara'");
		Else
			LabelText = NStr("vi = 'Quét mã vạch hàng hóa';
							|ru = 'Отск. ШК товара';
							|en = 'Scan item BC'; fa = 'Scan item BC';
							|it = 'Scansionate il codice a barre della merce';
							|pl = 'Zeskanuj KK towaru';
							|tr = 'Ürün BK tara'");
		EndIf;
	ElsIf LabelID = "HintScanInventoryArea" Then
		If (ScreenResolution = Resolution240x320)
			Or (ScreenResolution = Resolution320x320) Then
			LabelText = NStr("vi = 'Quét mã vạch chỗ hàng hóa';
							|ru = 'Отск. ШК тов. места';
							|en = 'Scan cargo packaging BC'; fa = 'Scan cargo packaging BC';
							|it = 'Scansionate il codice a barre del collo della merce';
							|pl = 'Zeskanuj KK miejsca towaru';
							|tr = 'Ürün yeri BK tara'");
		Else
			LabelText = NStr("vi = 'Hãy quét mã vạch hàng hóa';
							|ru = 'Отсканируйте ШК тов. места';
							|en = 'Scan cargo packaging barcode'; fa = 'Scan cargo packaging barcode';
							|it = 'Scansionate il codice a barre del collo della merce';
							|pl = 'Zeskanuj KK miejsca towaru';
							|tr = 'Ürün yeri BK tara'");
		EndIf;
	ElsIf LabelID = "HintScanSHKSeries" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hãy quét mã vạch sê-ri';
							|ru = 'Отсканируйте ШК серии';
							|en = 'Scan batch barcode'; fa = 'Scan batch barcode';
							|it = 'Scansionate il codice a barre della serie';
							|pl = 'Zeskanuj KK serii';
							|tr = 'Parti BK tara'");
		Else
			LabelText = NStr("vi = 'Quét mã vạch sê-ri';
							|ru = 'Отск. ШК серии';
							|en = 'Scan batch BC'; fa = 'Scan batch BC';
							|it = 'Scansionate il codice a barre della serie';
							|pl = 'Zeskanuj KK serii';
							|tr = 'Parti BK tara'");
		EndIf;
	ElsIf LabelID = "HeaderOfInformationReceived" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Nhận thông tin';
							|ru = 'Получение информации';
							|en = 'Obtaining information'; fa = 'Obtaining information';
							|it = 'Ricezione dell''informazione';
							|pl = 'Uzyskiwanie informacji';
							|tr = 'Bilgi alımı'");
		Else
			LabelText = NStr("vi = 'Nhận thông tin';
							|ru = 'Получ. информации';
							|en = 'Obt-g information'; fa = 'Obt-g information';
							|it = 'Ricezione dell''informazione';
							|pl = 'Uzyskiwanie informacji';
							|tr = 'Bilgi alımı'");
		EndIf;
	ElsIf LabelID = "CellProductReboundHint" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hãy quét mã vạch hàng hóa hoặc ô hàng.';
							|ru = 'Отсканируйте штрихкод товара или ячейки.';
							|en = 'Scan item barcode or bin barcode.'; fa = 'Scan item barcode or bin barcode.';
							|it = 'Scansionate il codice a barre della merce o della cella.';
							|pl = 'Zeskanuj kod kreskowy towaru lub komórki.';
							|tr = 'Ürün barkodu veya hücreleri tara'");
		Else
			LabelText = NStr("vi = 'Quét mã vạch hàng hóa hoặc ô hàng.';
							|ru = 'Отск. ШК товара или ячейки.';
							|en = 'Scan bin or item barcode'; fa = 'Scan bin or item barcode';
							|it = 'Scansionate il codice a barre della merce o della cella.';
							|pl = 'Zeskanuj KK towaru lub komórki.';
							|tr = 'Ürün BK veya hücreleri tara.'");
		EndIf;
	ElsIf LabelID = "HeadingToShipmentZone" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hãy chọn khu vực xuất hàng';
							|ru = 'Выберите зону отгрузки';
							|en = 'Select outbound area'; fa = 'Select outbound area';
							|it = 'Selezionate un area di spedizione';
							|pl = 'Wybierz strefę wysyłki';
							|tr = 'Yükleme alanını seç'");
		Else
			LabelText = NStr("vi = 'Chọn khu vực giao hàng';
							|ru = 'Выб.зону отгрузки';
							|en = 'Select out-d area'; fa = 'Select out-d area';
							|it = 'Selezionate un area di spedizione';
							|pl = 'Wybierz strefę wysyłki';
							|tr = 'Yükleme alanını seç'");
		EndIf;
	ElsIf LabelID = "HeaderForAcceptanceZone" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hãy chọn khu vực nhập hàng';
							|ru = 'Выберите зону приемки';
							|en = 'Select inbound area'; fa = 'انتخاب ناحیه ورودی';
							|it = 'Seleziona un area di accettazione';
							|pl = 'Wybierz miejsce odbioru';
							|tr = 'Boşaltma alanı seçin'");
		Else
			LabelText = NStr("vi = 'Chọn khu vực nhập hàng';
							|ru = 'Выб.зону приемки';
							|en = 'Select in-d area'; fa = 'Select in-d area';
							|it = 'Seleziona un area di accettazione';
							|pl = 'Wybierz strefę odbioru';
							|tr = 'Kabul alanını seç'");
		EndIf;
	ElsIf LabelID = "WarningPackingListHasAlreadyBeenScanned" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Đã quét phiếu đóng gói';
							|ru = 'Упаковочный лист уже отсканирован';
							|en = 'The packing list has already been scanned'; fa = 'The packing list has already been scanned';
							|it = 'Seleziona un area di accettazione';
							|pl = 'Wykaz ładunkowy został już zeskanowany';
							|tr = 'Ürün listesi tarandı'");
		Else
			LabelText = NStr("vi = 'Đã quét phiếu đóng gói';
							|ru = 'Упаковочный лист уже отсканирован';
							|en = 'The packing list has already been scanned'; fa = 'The packing list has already been scanned';
							|it = 'Seleziona un area di accettazione';
							|pl = 'Wykaz ładunkowy został już zeskanowany';
							|tr = 'Ürün listesi tarandı'");
		EndIf;
	ElsIf LabelID = "DestinationSelectionHeader" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Hãy chọn mục đích hàng hóa';
							|ru = 'Выберите назн-е товара';
							|en = 'Assign item'; fa = 'Assign item';
							|it = 'Selezionate l''assegnazione della merce';
							|pl = 'Wybierz miejsce docelowe towaru';
							|tr = 'Ürün atamasını seç'");
		Else
			LabelText = NStr("vi = 'Hãy chọn mục đích';
							|ru = 'Выберите назн-е';
							|en = 'As-n item'; fa = 'As-n item';
							|it = 'Selezionate l''assegnazione';
							|pl = 'Wybierz miejsce docelowe';
							|tr = 'Atamayı seç'");
		EndIf;
	ElsIf LabelID = "TitleForMarkingCellForRecalculation" Then
		If (ScreenResolution = Resolution240x320)
			Or (ScreenResolution = Resolution320x320) Then
			LabelText = NStr("vi = 'Đánh dấu các ô để kiểm đếm';
							|ru = 'Пометка яч. к пересчету';
							|en = 'Mark bin for phys. count'; fa = 'Mark bin for phys. count';
							|it = 'Contrassegno cella da ricalcolare';
							|pl = 'Odznaczanie komórki do przeliczenia';
							|tr = 'Yeniden sayım için hücre işaretleme'");
		Else
			LabelText = NStr("vi = 'Đánh dấu ô để tính lại';
							|ru = 'Пометка ячейки к пересчету';
							|en = 'Mark bin for physical count'; fa = 'Mark bin for physical count';
							|it = 'Contrassegno celle da ricalcolare';
							|pl = 'Odznaczanie komórki do przeliczenia';
							|tr = 'Yeniden sayım için hücre işaretleme'");
		EndIf;
	ElsIf LabelID = "HintCellBounceToRecalculate" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Quét mã vạch hoặc nhập địa chỉ ô.';
							|ru = 'Отсканируйте штрихкод или введите адрес ячейки.';
							|en = 'Scan barcode or enter bin address.'; fa = 'Scan barcode or enter bin address.';
							|it = 'Scansionate il codice a barre o inserite l''indirizzo della cella.';
							|pl = 'Zeskanuj kod kreskowy lub wpisz adres komórki.';
							|tr = 'Barkodu tarayın veya hücre adresini girin'");
		Else
			LabelText = NStr("vi = 'Quét mã vạch hoặc nhập địa chỉ của ô.';
							|ru = 'Отск. ШК или введите адрес ячейки.';
							|en = 'Scan BC or enter bin address.'; fa = 'Scan BC or enter bin address.';
							|it = 'Scansionate il codice a barre o inserite l''indirizzo della cella.';
							|pl = 'Zeskanuj kod kreskowy lub wpisz adres komórki.';
							|tr = 'BK tarayın veya hücre adresini girin.'");
		EndIf;
	ElsIf LabelID = "ErrorSmallerNumber" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Lỗi: số tiền không được nhỏ hơn %1.';
							|ru = 'Ошибка: количество не должно быть меньше %1.';
							|en = 'Error: number of days cannot be less than %1.'; fa = 'Error: number of days cannot be less than %1.';
							|it = 'Errore: la quantità non deve essere inferiore a %1.';
							|pl = 'Błąd: ilość nie powinna być mniejsza niż %1.';
							|tr = 'Hata: Miktar %1''den az olmamalıdır.'");
		Else
			LabelText = NStr("vi = 'Lỗi: số lượng không nhỏ hơn  %1.';
							|ru = 'Ошибка: кол-во не д.б. мен. %1.';
							|en = 'Err: number of days cannot be less than %1.'; fa = 'Err: number of days cannot be less than %1.';
							|it = 'Errore: la quantità non deve essere inferiore a %1.';
							|pl = 'Błąd: ilość nie powinna być mniejsza niż %1.';
							|tr = 'Hata: Miktar %1''den az olmamalıdır.'");
		EndIf;
	ElsIf LabelID = "CellsAreNotMatched" Then
		If Not (ScreenResolution = Resolution240x320) Then
			LabelText = NStr("vi = 'Chưa chọn ô thay thế.';
							|ru = 'Альтернативные ячейки не подобраны.';
							|en = 'Alternate bins not picked.'; fa = 'Alternate bins not picked.';
							|it = 'Celle alternative non selezionate.';
							|pl = 'Alternatywne komórki nie zostały dobrane.';
							|tr = 'Alternatif hücreler seçilmedi.'");
		Else
			LabelText = NStr("vi = 'Chưa chọn ô thay thế.';
							|ru = 'Альтернативные ячейки не подобраны.';
							|en = 'Alternate bins not picked.'; fa = 'Alternate bins not picked.';
							|it = 'Celle alternative non selezionate.';
							|pl = 'Alternatywne komórki nie zostały dobrane.';
							|tr = 'Alternatif hücreler seçilmedi.'");
		EndIf;
	EndIf;
	
	NewRow = Form.HeaderLabelTexts.Add();
	NewRow.LabelID = LabelID;
	NewRow.LabelText = LabelText;
	
EndProcedure

// Loads text labels for form elements in a special table of values.
// In the future, depending on the form for which permission is open
// , the desired title text is displayed.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure UploadCaptionTextsForFormHeaders(Form)
	
	Form.HeaderLabelTexts.Clear();
	
	AddElementCaptionText(Form, "TitleAllSelectionTasks");
	AddElementCaptionText(Form, "TitleMySelectionTasks");
	AddElementCaptionText(Form, "TitleAllPlacementTasks");
	AddElementCaptionText(Form, "TitleMyPlacementTasks");
	AddElementCaptionText(Form, "TitleAllMovingTasks");
	AddElementCaptionText(Form, "HeadingMyMovingTasks");
	AddElementCaptionText(Form, "TitleAllRecalculationTasks");
	AddElementCaptionText(Form, "TitleMyRecalculationTasks");
	AddElementCaptionText(Form, "TitleAllTasksForAcceptance");
	AddElementCaptionText(Form, "TitleMyAcceptanceTasks");
	AddElementCaptionText(Form, "TitleAllTasksForReview");
	AddElementCaptionText(Form, "TitleMyVerificationTasks");
	AddElementCaptionText(Form, "WrongCellError");
	AddElementCaptionText(Form, "ErrorWrongProduct");
	AddElementCaptionText(Form, "ErrorProductNotFound");
	AddElementCaptionText(Form, "WarningUnknownBarcode");
	AddElementCaptionText(Form, "ErrorUpSheetContainsPreviouslyScannedUpSheets");
	AddElementCaptionText(Form, "ErrorIsNotLinked");
	AddElementCaptionText(Form, "ErrorIsWrongSeries");
	AddElementCaptionText(Form, "ErrorSeriesIsNotUnique");
	AddElementCaptionText(Form, "ErrorIncorrectQuantity");
	AddElementCaptionText(Form, "ErrorQuantityGreaterThanRequired");
	AddElementCaptionText(Form, "HeaderSelects");
	AddElementCaptionText(Form, "HintScanSCOfAcceptanceZone");
	AddElementCaptionText(Form, "HintScanWKCells");
	AddElementCaptionText(Form, "HintScanProductProfile");
	AddElementCaptionText(Form, "HintScanSHKSeries");
	AddElementCaptionText(Form, "HeaderOfInformationReceived");
	AddElementCaptionText(Form, "CellProductReboundHint");
	AddElementCaptionText(Form, "HeadingToShipmentZone");
	AddElementCaptionText(Form, "HeaderForAcceptanceZone");
	AddElementCaptionText(Form, "WarningProductMissingFromTask");
	AddElementCaptionText(Form, "WarningProductSelectedOverorder");
	AddElementCaptionText(Form, "WarningPackingListHasAlreadyBeenScanned");
	AddElementCaptionText(Form, "HintScanInventoryArea");
	AddElementCaptionText(Form, "DestinationSelectionHeader");
	AddElementCaptionText(Form, "TitleForMarkingCellForRecalculation");
	AddElementCaptionText(Form, "HintCellBounceToRecalculate");
	AddElementCaptionText(Form, "ErrorSmallerNumber");
	AddElementCaptionText(Form, "CellsAreNotMatched");
	
EndProcedure

// Returns the label text for the form element.
// 
// Parameters:
//	LabelID - String - label ID,
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	String - The text of the inscription.
//
Function CaptionTextOfFormElementTitle(LabelID, Form)
	
	Filter = New Structure("LabelID", LabelID);
	RowsArray = Form.HeaderLabelTexts.FindRows(Filter);
	
	If RowsArray.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Return RowsArray[0].LabelText;
	
EndFunction

// The function returns a reference to the warehouse operation type depending on the string description
// of the operation type (document type).
//
// Parameters:
//	OperationKind - String - type of operation.
//
// Returns:
//	EnumRef.OperationKindsOfGoodsPlacementPicking - type of warehouse operation.
//
Function TypeOfPlacementSelectionOperation(OperationKind) Export
	
	If OperationKind = "Filter" Then
		Return Enums.OperationKindsOfGoodsPlacementPicking.Filter;
	ElsIf OperationKind = "Location" Then
		Return Enums.OperationKindsOfGoodsPlacementPicking.Location;
	ElsIf OperationKind = "Move" Then
		Return Enums.OperationKindsOfGoodsPlacementPicking.Move;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// The procedure sets the title of the main menu item for selecting an operation on the form.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items -  FormAllItems - elements of the warehouse employee's workplace form.
//	TagName - String - element name.
//	ItemTitle - String - item header.
//	JobsCount - Number - the number of documents tasks,.
//
Procedure SetPropertiesOfMainMenuItem(Form, TagName, ItemTitle, JobsCount)
	
	Item = Form.Items[TagName]; // FormGroup, FormTable, FormField, FormButton
	
	HasJobs = (JobsCount > 0);
	DocumentsCount = ?(JobsCount > 0, "(" + JobsCount + ")", "");
	
	// Set the title.
	
	// The title text of the main menu item consists of several parts:
	// the code of the main menu.Element Name[ (Number of tasks)], for example:
	// "0.Selection (3)".
	//
	// In this procedure, only the values of the parts are set: <Element name> and <Number of tasks>.
	
	// ... check if the element command has a hotkey.
	Shortcut = Form.Commands[TagName].Shortcut;
	
	KeyPresentation_ = KeyboardShortcutPresentation(Shortcut);
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(
		?(ValueIsFilled(KeyPresentation_), NStr("vi = '%1%2 %3';
												|ru = '%1%2 %3';
												|en = '%1.%2 %3'; fa = '%1.%2 %3';
												|it = '%1%2 %3';
												|pl = '%1%2 %3';
												|tr = '%1%2 %3'"), NStr("vi = '%2 %3';
																		|ru = '%2 %3';
																		|en = '%2 %3'; fa = '%2 %3';
																		|it = '%2 %3';
																		|pl = '%2 %3';
																		|tr = '%2 %3'")), 
		KeyPresentation_, ItemTitle, DocumentsCount);
	
	Item.Title = TitleText;
	Item.Enabled = HasJobs;
	
EndProcedure

// Returns the string representation of the hotkey.
//
// Parameters:
//	Shortcut - Key - the key.
//
// Returns:
//	String - hotkey representation.
//
Function KeyboardShortcutPresentation(Shortcut)
	
	If Shortcut = Undefined Then
		Return "";
	EndIf;
	
	If Shortcut.Key = Key.None Then
		Return "";
	EndIf;
	
	Return StrReplace(String(Shortcut.Key), "_", "");
	
EndFunction

// Checks that the scanned cell matches the cell in the scan line.
//
// Parameters:
//	ScanLine - Structure, ValueTableRow - the scan line.
//
// Returns:
//	Boolean - True, the scanned storage cell corresponds to the value of the address of the storage cell 
//			to be scanned.
//
Function ScannedCellIsSameAsCellOfScanLine(ScanLine)
	
	Return (ScanLine.Cell = ScanLine.SKCell);
	
EndFunction

// Checks that the cell matches the cell in the scan line.
//
// Parameters:
//	ScanLine - Structure, ValueTableRow - the scan line.
//
// Returns:
//	Boolean - True, the storage cell corresponds to the value of the address of the storage cell to be scanned.
//
Function CellIsSameAsCellOfScanLine(ScanLine, Cell)
	
	Return (ScanLine.Cell = Cell)
	
EndFunction

// Checks that the series coincides with the series of scan rows.
//
// Parameters:
//	ScanLine - Structure, ValueTableRow - the scan line.
//
// Returns:
//	Boolean - True, the scanned product series corresponds to the value of the product series to be scanned.
//
Function SeriesIsSameAsScanLineSeries(ScanLine, Series)
	
	Return (ScanLine.Series = Series);
	
EndFunction

// Checks that the item matches the item in the scan line.
//
// Parameters:
//	ScanLine - Structure, ValueTableRow - the scan line.
//
// Returns:
//	Boolean - True, the scanned product corresponds to the value of the product to be scanned.
//
Function ItemMatchesScanLineItem(ScanLine, OwnGoods)
	
	Return (ScanLine.Products = OwnGoods.Products)
		And (ScanLine.Characteristic = OwnGoods.Characteristic)
		And (ScanLine.Package = OwnGoods.Package)
		And (ScanLine.PackingList = OwnGoods.PackingList);
	
EndFunction

// Checks that the scanned item matches the item in the scan line.
//
// Parameters:
//	ScanLine - Structure, ValueTableRow - the scan line.
//
// Returns:
//	Boolean - True, the product corresponds to the value of the product to be scanned.
//
Function ScannedItemMatchesItemOfScanLine(ScanLine)
	
	Return (ScanLine.Products = ScanLine.SKProducts) 
		And (ScanLine.Characteristic = ScanLine.SCCharacteristics)
		And (ScanLine.Package = ScanLine.SkPackaging)
		And (ScanLine.Series = ScanLine.SkSeries)
		And (ScanLine.PackingList = ScanLine.ScPackingList);
	
EndFunction

// Fills in the values of the fields of the scan line structure with the values of the fields
// of the found product.
//
// Parameters:
//	ScanLine - Structure, ValueTableRow - the scan line.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
Procedure FillInPropertyValuesOfScannedProduct(ScanLine, OwnGoods)
	
	ScanLine.SKProducts   = OwnGoods.Products;
	ScanLine.SCCharacteristics = OwnGoods.Characteristic;
	ScanLine.SkPackaging       = OwnGoods.Package;
	
	ScanLine.Barcode              = OwnGoods.Barcode;
	ScanLine.QuantityByBarcode = OwnGoods.QuantityByBarcode;
	
EndProcedure

// Checks whether the manually entered batch expiration date is correct.
//
// Parameters:
//	Venomancer Spravochnike.Nomenclature view - type of nomenclature,
//	ExpirationDateByString - String - shelf life of the series by line,
//	ExpirationDate_ - Undefined - a variable that records the expiration date received from the string.
//
// Returns:
//	Boolean - True - the expiration date is correct, False - not.
//
Function ShelfLifeOfSeriesIsCorrect(SeriesIndicationParameters, Val ExpirationDateByString, ExpirationDate_ = Undefined)
	
	DateAsString = "";
	ExpirationDateByString = TrimAll(ExpirationDateByString);
	
	If SeriesIndicationParameters.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
		// MM.yy
		DateAsString = "20" + Right(ExpirationDateByString, 2) + Left(ExpirationDateByString, 2) + "01000000";
	ElsIf SeriesIndicationParameters.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToDays Then
		// dd.MM.yy
		DateAsString = "20" + Right(ExpirationDateByString, 2) + Mid(ExpirationDateByString, 4, 2)
			+ Left(ExpirationDateByString, 2) + "000000";
	ElsIf SeriesIndicationParameters.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
		// dd.MM.yy-HH
		DateAsString = "20" + Mid(ExpirationDateByString, 7, 2) + Mid(ExpirationDateByString, 4, 2) + Left(ExpirationDateByString, 2)
			+ Right(ExpirationDateByString, 2) + "0000";
	EndIf;
	
	Try
		ExpirationDate_ = Date(DateAsString);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Sets the properties of the field for entering the expiration date of the item series on the page "pageselection Values".
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 			** SeriesShelfLife - TextBox - field for entering the expiration date of the series.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
Procedure SetSeriesExpirationProperties(Form, OwnGoods)
	
	If Not ValueIsFilled(OwnGoods.Products) Then
		Return;
	EndIf;
	
	Form.Items.SeriesShelfLife.Mask = "";
	
	If Not OwnGoods.UseShelfLifeOnBatchRegistration Then
		Return;
	EndIf;
	
	If OwnGoods.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
		Mask = "99.99";
	ElsIf OwnGoods.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToDays Then
		Mask = "99.99.99";
	ElsIf OwnGoods.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
		Mask = "99.99.99-99";
	EndIf;
	
	Form.Items.SeriesShelfLife.Mask = Mask;
	
EndProcedure

// Checks whether the scanned item exists in the list of items in the task.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
// Returns:
//	Boolean - The truth is the product is in the task, the lie is not.
//
Function ProductIsInTask(Form, OwnGoods)
	
	Filter = New Structure("Products, Characteristic, Purpose, Package");
	FillPropertyValues(Filter, OwnGoods);
	
	RowsArray = Form.GoodsForScanning.FindRows(Filter);
	
	Return (RowsArray.Count() > 0);
	
EndFunction

// Checks whether the product is available for scanning.
// When scanning the task items in the "Product-Cell" processing order
// , a situation may occur when the task line with the specified product
// has already been scanned. in this case, an exception should be raised.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
// Returns:
//	Boolean - True - the series is available for scanning, False - not.
//
Function ProductIsAvailableForScanning(Form, OwnGoods)
	
	Filter = New Structure("Products, Characteristic, Package");
	FillPropertyValues(Filter, OwnGoods);
	
	RowsArray = Form.GoodsForScanning.FindRows(Filter);
	
	If RowsArray.Count() = 0 Then
		Return False;
	EndIf;
	
	ProductAvailable = False;
	
	For Each TBLString In RowsArray Do
		If TBLString.NumberOfPackagingsScanned <> TBLString.NumberOfPackages Then
			ProductAvailable = True;
			Break;
		EndIf;
	EndDo;
	
	Return ProductAvailable;
	
EndFunction

// Checks whether the scanned series exists in the task's product list.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace..
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//	Series - CatalogRef.ItemsBatches - product series.
//
// Returns:
//	Boolean - The truth is that the product series is in the task, the lie is not.
//
Function ProductSeriesIsInTask(Form, OwnGoods, Series)
	
	JobType = Form.ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If (JobType = "Filter"
			Or JobType = "Location")
		And SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) Then
		
		Filter = New Structure("Products, Characteristic, Package, BatchNumber, ValidUntil_");
		FillPropertyValues(Filter, OwnGoods);
		
		Filter.BatchNumber = CurrentScanningLine.BatchNumber;
		Filter.ValidUntil_ = CurrentScanningLine.ValidUntil_;
	Else
		Filter = New Structure("Products, Characteristic, Package, Series");
		FillPropertyValues(Filter, OwnGoods);
		
		Filter.Series = Series;
	EndIf;
	
	RowsArray = Form.GoodsForScanning.FindRows(Filter);
	If RowsArray.Count() = 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Clears the values of fields that store information about the scanned product.
//
// Parameters:
//	ScanLine - Structure - the scan line.
//
Procedure ClearScannedProductFields(ScanLine)
	
	ScanLine.SKProducts = Catalogs.Products.EmptyRef();
	ScanLine.SCCharacteristics = Catalogs.ItemsCharacteristics.EmptyRef();
	ScanLine.SkPackaging = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	ScanLine.SkSeries = Catalogs.ItemsBatches.EmptyRef();
	
EndProcedure

// Resets the active row flag for all rows in the product table to be scanned.
//
// Parameters:
//	GoodsForScanning - FormDataCollection - table of products to scan.
//
Procedure ResetMarkOfActiveLineOfScanItems(GoodsForScanning)
	
	For Each TableRow In GoodsForScanning Do
		TableRow.ActiveString = 0;
	EndDo;
	
EndProcedure

// Sets the activity flag for the product scan line.
//
// Parameters:
//	ScanLine - Structure - the scan line of goods.
//
Procedure SetScanLineActivity(ScanLine)
	
	ScanLine.ActiveString = 1;
	
EndProcedure

// Finds a row with a product (product+series) in the product table for scanning and sets it as the current scan row.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
Procedure GoToProductLineWithSeries(Form, OwnGoods)
	
	JobType = Form.ModeSettings.JobType;
	GoodsForScanning = Form.GoodsForScanning;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If (JobType = "Filter"
			Or JobType = "Move")
		And SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) Then
		
		Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber, ValidUntil_");
		
	Else
		Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
	EndIf;
	
	If Filter.Cell = Undefined Then
		Filter.Cell = Catalogs.StorageBins.EmptyRef();
	EndIf;
	
	FillPropertyValues(Filter, OwnGoods);
	
	RowsArray = Form.GoodsForScanning.FindRows(Filter);
	If RowsArray.Count() = 0 Then
		Return;
	EndIf;
	
	ProductLineFound = False;
	
	For Each TBLString In RowsArray Do
		If TBLString.NumberOfPackages > TBLString.NumberOfPackagingsScanned Then
			ProductLineFound = True;
			Break;
		EndIf;
	EndDo;
	
	If ProductLineFound
		Or Form.ModeSettings.JobType = "PickingCheck" Then
		
		FillPropertyValues(CurrentScanningLine, TBLString);
		ClearScannedProductFields(CurrentScanningLine);
		ResetMarkOfActiveLineOfScanItems(GoodsForScanning);
		SetScanLineActivity(TBLString);
		
		CurrentScanningLine.NumberOfPackagesPut = CurrentScanningLine.NumberOfPackagingsScanned;
		CurrentScanningLine.SKProducts = CurrentScanningLine.Products;
		CurrentScanningLine.SCCharacteristics = CurrentScanningLine.Characteristic;
		CurrentScanningLine.SkSeries = CurrentScanningLine.Series;
		CurrentScanningLine.SKSeriesNumber = CurrentScanningLine.BatchNumber;
		CurrentScanningLine.SKIsGoodTo = CurrentScanningLine.ValidUntil_;
		CurrentScanningLine.SkPackaging = CurrentScanningLine.Package;
		
		Form.CurrentScanningLine = CurrentScanningLine;
	EndIf;
	
EndProcedure

// Finds the item row in the product table for scanning and sets it as the current scan row.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
Procedure GoToProductLine(Form, OwnGoods)
	
	GoodsForScanning = Form.GoodsForScanning;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	Filter = New Structure("Products, Characteristic, Package");
	FillPropertyValues(Filter, OwnGoods);
	
	RowsArray = Form.GoodsForScanning.FindRows(Filter);
	If RowsArray.Count() = 0 Then
		Return;
	EndIf;
	
	ProductLineFound = False;
	
	For Each TBLString In RowsArray Do
		If TBLString.NumberOfPackages > TBLString.NumberOfPackagingsScanned Then
			ProductLineFound = True;
			Break;
		EndIf;
	EndDo;
	
	If ProductLineFound Then
		FillPropertyValues(CurrentScanningLine, TBLString);
		ClearScannedProductFields(CurrentScanningLine);
		ResetMarkOfActiveLineOfScanItems(GoodsForScanning);
		SetScanLineActivity(TBLString);
		
		CurrentScanningLine.SKProducts             = CurrentScanningLine.Products;
		CurrentScanningLine.SCCharacteristics           = CurrentScanningLine.Characteristic;
		CurrentScanningLine.SkPackaging                 = CurrentScanningLine.Package;
		
		CurrentScanningLine.NumberOfPackagesPut = CurrentScanningLine.NumberOfPackagingsScanned;
		
		CurrentScanningLine.Barcode              = OwnGoods.Barcode;
		CurrentScanningLine.QuantityByBarcode = OwnGoods.QuantityByBarcode;
		
		Form.CurrentScanningLine = CurrentScanningLine;
	EndIf;
	
EndProcedure

// Adds information about reference series to the table of products to be scanned.
//
// Parameters:
//	Form - ClientApplicationForm:
// 		* GoodsForScanning - FormDataCollection - table of products to be scanned.
//	OwnGoods - See OwnGoods
//	Series - CatalogRef.ItemsBatches - product series.
//
// Returns:
//	Boolean - True if the reference series of the product is specified in the table of products that need to be scanned.
//
Function CheckAddReferenceSeriesToProductsForScanning(Form, OwnGoods, Series)
	
	GoodsForScanning = Form.GoodsForScanning;
	
	FilterOwnGoods = New Structure("Products, Characteristic, Package");
	FillPropertyValues(FilterOwnGoods, OwnGoods);
	
	FilterSeries = New Structure("Products, Characteristic, Package, Series");
	FillPropertyValues(FilterSeries, OwnGoods);
	FilterSeries.Series = Series;
	
	RowsArray = Form.GoodsForScanning.FindRows(FilterOwnGoods);
	If RowsArray.Count() = 0 Then
		Return False;
	EndIf;
	
	RowsBySeries = Form.GoodsForScanning.FindRows(FilterSeries);
	If RowsBySeries.Count() > 0 Then
		Form.ModeSettings.MessageID_ = "ErrorSeriesIsNotUnique";
		Form.ModeSettings.DisplayWarningWhenScanning = True;
		
		Return True;
	EndIf;
	
	ProductLineFound = False;
	
	For Each TBLString In RowsArray Do
		If TBLString.NumberOfPackages > TBLString.NumberOfPackagingsScanned Then
			ProductLineFound = True;
			Break;
		EndIf;
	EndDo;
	
	If Not ProductLineFound Then
		Return False;
	EndIf;
	
	If TBLString.NumberOfPackagingsScanned = 0 Then
		// This is the first scan for this product with a reference series
		RowWithReferenceSeries = TBLString;
	Else
		TotalNumberOfPackages = TBLString.NumberOfPackages - TBLString.NumberOfPackagingsScanned;
		RemainingNumberOfPackagesDoNotShip = TBLString.NumberOfPackagesDoNotShip
			- Min(TBLString.NumberOfPackagesDoNotShip, TBLString.NumberOfPackagingsScanned);
		TBLString.NumberOfPackages = TBLString.NumberOfPackages - TotalNumberOfPackages;
		TBLString.NumberOfPackagesInDocument = TBLString.NumberOfPackagesInDocument - TotalNumberOfPackages;
		TBLString.NumberOfPackagesDoNotShip = TBLString.NumberOfPackagesDoNotShip -
			RemainingNumberOfPackagesDoNotShip;
	
		RowsArray = Form.GoodsForScanning.FindRows(FilterSeries);
		If RowsArray.Count() > 0 Then
			
			// If a line with a reference series has already been added, you need to transfer the remainder to this line for scanning.
			RowWithReferenceSeries = RowsArray[0];
			RowWithReferenceSeries.NumberOfPackages = RowWithReferenceSeries.NumberOfPackages +
				TotalNumberOfPackages;
			RowWithReferenceSeries.NumberOfPackagesInDocument = RowWithReferenceSeries.NumberOfPackagesInDocument +
				TotalNumberOfPackages;
			RowWithReferenceSeries.NumberOfPackagesDoNotShip = RowWithReferenceSeries.NumberOfPackagesDoNotShip +
				RemainingNumberOfPackagesDoNotShip;
			
		Else
			
			IndexOfTableRow = Form.GoodsForScanning.IndexOf(TBLString);
			
			RowWithReferenceSeries = GoodsForScanning.Insert(IndexOfTableRow + 1);
			FillPropertyValues(RowWithReferenceSeries, TBLString);
			RowWithReferenceSeries.NumberOfPackages = TotalNumberOfPackages;
			RowWithReferenceSeries.NumberOfPackagesInDocument = TotalNumberOfPackages;
			RowWithReferenceSeries.NumberOfPackagesDoNotShip = RemainingNumberOfPackagesDoNotShip;
			
		EndIf;
	EndIf;
	
	RowWithReferenceSeries.Series = Series;
	
	Return True;
	
EndFunction

// Checks that the passed processing order is the Product-Cell processing order.
//
// Parameters:
//	ProcessingProcedure_ - EnumRef.WarehouseJobProcessingProcedure - the order of processing.
//
// Returns:
//	Boolean - True is the order of processing "Product-Cell", False is not.
//
Function ThisIsProcessingOrderOfItemCell(ProcessingProcedure_)
	
	Return (ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.GoodsBin);
	
EndFunction

// Finds the item row in the product table for scanning and sets it as the current scan row.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//	HasErrors - Undefined - a variable that contains the error flag.
//
Procedure AfterScanningProduct(Form, OwnGoods, HasErrors)
	
	JobType = Form.ModeSettings.JobType;
	
	If HasErrors Then
		Return;
	EndIf;
	
	ModeSettings = Form.ModeSettings;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	ProcessingProcedure_ = Form.ModeSettings.ProcessingProcedure_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	ThisIsUnknownBarcode = ThisIsUnknownBarcode(OwnGoods);
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(ProcessingProcedure_);
	
	FillInProductWeightByBarcode(OwnGoods);
	SetSeriesExpirationProperties(Form, OwnGoods);
	
	If ThisIsSetOfGoods
		Or JobType = "Recalculate"
		Or JobType = "PickingCheck" Then
		
		StatusOfSeriesIndication = StatusOfSeriesIndication(OwnGoods.Products, Form.Warehouse, Form.Premise,
			Form.ModeSettings.Job, Form.ModeSettings.JobType);
		
		SeriesAreSpecified = SeriesAreSpecified(StatusOfSeriesIndication);
		
	Else
		If JobType = "Filter"
			Or JobType = "Move" Then
			
			SeriesAreSpecified = ValueIsFilled(OwnGoods.BatchNumber)
				Or ValueIsFilled(OwnGoods.ValidUntil_)
				Or (Form.CurrentScanningLine.BatchesIndicationStatus > 0);
				
		Else
			SeriesAreSpecified = ValueIsFilled(OwnGoods.Series)
				Or Form.CurrentScanningLine.BatchesIndicationStatus > 0;
		EndIf;
	EndIf;
	
	SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
	
	If Not SeriesAreSpecified Then
		SelectAppointment(Form, OwnGoods);
	EndIf;
	
	If ThisIsSetOfGoods Then
		
		If Not ThisIsUnknownBarcode
			And ItemMatchesScanLineItem(Form.CurrentScanningLine, OwnGoods) Then
			
			Form.CurrentScanningLine.Barcode              = OwnGoods.Barcode;
			Form.CurrentScanningLine.QuantityByBarcode = OwnGoods.QuantityByBarcode;
			
		Else
			
			Form.CurrentScanningLine = ScanLine();
			
			FillPropertyValues(Form.CurrentScanningLine, OwnGoods);
			FillInPropertyValuesOfScannedProduct(Form.CurrentScanningLine, OwnGoods);
			
			Form.CurrentScanningLine.SKCell = ModeSettings.ReceivingArea;
			Form.CurrentScanningLine.SKCellCode = ModeSettings.NameOfAcceptanceZone;
			
			Form.CurrentScanningLine.BatchesIndicationStatus = StatusOfSeriesIndication;
			
		EndIf;
		
		If Not SeriesAreSpecified Then
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				IncreaseScannedNumberOfPackages(Form, 1);
				AddToScannedProducts(Form);
				
			Else
				
				If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
					IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
					AddToScannedProducts(Form);
				Else
					ScanToEnterTheNumber(Form);
					Return;
				EndIf;
			EndIf;
			
		EndIf;
		
		If JobType = "Receiving"
			Or JobType = "Location" Then
			
			GoToNextScanOption(Form);
			
		EndIf;
		
	Else
		
		If JobType = "Filter" Then
			
			FillInPropertyValuesOfScannedProduct(Form.CurrentScanningLine, OwnGoods);
			
			If Not SeriesAreSpecified Then
				
				If ValueIsFilled(Form.CurrentScanningLine.Package)
					Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
						And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
					
					IncreaseScannedNumberOfPackages(Form, 1);
					SetScannedQuantityOfGoods(Form);
					
				Else
					
					If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
						If BarcodeQuantityIsCorrect(Form) Then
							IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
							SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
						EndIf;
					Else
						ScanToEnterTheNumber(Form);
					EndIf;
				EndIf;
				
			Else
				GoToNextScanOption(Form);
			EndIf;
			
		ElsIf JobType = "Location" Then
			
			If ThisIsProcessingOrderOfItemCell Then
				
				GoToProductLine(Form, OwnGoods);
				
				If Not SeriesAreSpecified Then
					
					FillInPropertyValuesOfScannedProduct(Form.CurrentScanningLine, OwnGoods);
					
					If ValueIsFilled(Form.CurrentScanningLine.Package)
						Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
							And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
						
						IncreaseScannedNumberOfPackages(Form, 1);
						SetScannedQuantityOfGoods(Form);
						
					Else
						
						If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
							If BarcodeQuantityIsCorrect(Form) Then
								IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
								SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
							EndIf;
						Else
							ScanToEnterTheNumber(Form);
						EndIf;
						
					EndIf;
					
				EndIf;
				
			Else
				
				FillInPropertyValuesOfScannedProduct(Form.CurrentScanningLine, OwnGoods);
				
				If Not SeriesAreSpecified Then
					
					If ValueIsFilled(Form.CurrentScanningLine.Package)
						Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
							And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
						
						IncreaseScannedNumberOfPackages(Form, 1);
						SetScannedQuantityOfGoods(Form);
						
					Else
						
						If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
							If BarcodeQuantityIsCorrect(Form) Then
								IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
								SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
							EndIf;
						Else
							ScanToEnterTheNumber(Form);
						EndIf;
						
					EndIf;
					
				Else
					GoToNextScanOption(Form);
				EndIf;
				
			EndIf;
			
		ElsIf JobType = "Move" Then
			
			If SelectionScanned
				And ThisIsProcessingOrderOfItemCell Then
				
				GoToProductLine(Form, OwnGoods);
				
				If Not SeriesAreSpecified Then
					
					FillInPropertyValuesOfScannedProduct(Form.CurrentScanningLine, OwnGoods);
					
					If ValueIsFilled(Form.CurrentScanningLine.Package)
						Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
							And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
						
						IncreaseScannedNumberOfPackages(Form, 1);
						SetScannedQuantityOfGoods(Form);
						
					Else
						
						If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
							If BarcodeQuantityIsCorrect(Form) Then
								IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
								SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
							EndIf;
						Else
							ScanToEnterTheNumber(Form);
						EndIf;
						
					EndIf;
					
				EndIf;
				
			Else
				
				FillInPropertyValuesOfScannedProduct(Form.CurrentScanningLine, OwnGoods);
				
				If Not SeriesAreSpecified Then
					
					If ValueIsFilled(Form.CurrentScanningLine.Package)
						Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
							And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
						
						IncreaseScannedNumberOfPackages(Form, 1);
						SetScannedQuantityOfGoods(Form);
						
					Else
						
						If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
							If BarcodeQuantityIsCorrect(Form) Then
								IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
								SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
							EndIf;
						Else
							ScanToEnterTheNumber(Form);
						EndIf;
						
					EndIf;
					
				Else
					GoToNextScanOption(Form);
				EndIf;
				
			EndIf;
			
		ElsIf JobType = "PickingCheck" Then
			
			ProductIsInTask = ProductIsInTask(Form, OwnGoods);
			
			If ProductIsInTask Then
				GoToProductLineByProduct(Form, OwnGoods);
			Else
				
				NumberOfProductItems = Form.CurrentScanningLine.QuantityOfGoodsInABin + 1;
				Form.CurrentScanningLine = ScanLine();
				FillPropertyValues(Form.CurrentScanningLine, OwnGoods);
				
				Form.CurrentScanningLine.BatchesIndicationStatus = StatusOfSeriesIndication;
				Form.CurrentScanningLine.GoodsNumberInTheBin = NumberOfProductItems;
				Form.CurrentScanningLine.QuantityOfGoodsInABin = NumberOfProductItems;
				
				SetScannedNumberOfPackages(Form, 0);
				
			EndIf;
			
			FillInPropertyValuesOfScannedProduct(Form.CurrentScanningLine, OwnGoods);
			
			If Not SeriesAreSpecified Then
				
				// Set a sign of the need to display a warning about a product that is missing in the task.
				If Not ProductIsInTask Then
					Form.ModeSettings.DisplayWarningWhenScanning = True;
					Form.ModeSettings.MessageID_ = "WarningProductMissingFromTask";
				EndIf;
				
				If ValueIsFilled(Form.CurrentScanningLine.Package)
					Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
						And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
					
					IncreaseScannedNumberOfPackages(Form, 1);
					AddToScannedProducts(Form);
					
				Else
					
					If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
						IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
						AddToScannedProducts(Form);
					Else
						ScanToEnterTheNumber(Form);
						Return;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			ResetSignsOfScanningAllParameters(Form);
			SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
			
			If Not SeriesAreSpecified Then
				SetParameterScanFlag(Form, "Products", True);
			EndIf;
			
			GoToNextScanOption(Form);
			
		ElsIf JobType = "Recalculate" Then
			
			If Not ItemMatchesScanLineItem(Form.CurrentScanningLine, OwnGoods) Then
				
				CurCell_ = Form.CurrentScanningLine.Cell;
				NumberOfBins = Form.CurrentScanningLine.NumberOfBins;
				CellNumber = Form.CurrentScanningLine.CellNumber;
				
				Form.CurrentScanningLine = ScanLine();
				
				Form.CurrentScanningLine.Cell = CurCell_;
				Form.CurrentScanningLine.SKCell = CurCell_;
				Form.CurrentScanningLine.NumberOfBins = NumberOfBins;
				Form.CurrentScanningLine.CellNumber = CellNumber;
				
				FillPropertyValues(Form.CurrentScanningLine, OwnGoods);
				FillInPropertyValuesOfScannedProduct(Form.CurrentScanningLine, OwnGoods);
				
				Form.CurrentScanningLine.BatchesIndicationStatus = StatusOfSeriesIndication;
				SetScannedNumberOfPackages(Form, 0);
				
			EndIf;
			
			If Not SeriesAreSpecified Then
				
				If ValueIsFilled(Form.CurrentScanningLine.Package)
					Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
						And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
					
					SetScannedNumberOfPackages(Form, 1);
					AddToScannedProducts(Form);
					
				Else
					
					If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
						SetScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
						AddToScannedProducts(Form);
					Else
						ScanToEnterTheNumber(Form);
						Return;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			ResetSignsOfScanningAllParameters(Form);
			SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
			
			If Not SeriesAreSpecified Then
				SetParameterScanFlag(Form, "Products", True);
			EndIf;
			
			GoToNextScanOption(Form);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Selects the purpose of separate storage for the product table of products that need to be sanitized.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 		* GoodsForScanning - FormDataCollection - table of products to be scanned.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
Procedure SelectAppointment(Form, OwnGoods)
	
	Object = Form.Object;
	ModeSettings = Form.ModeSettings;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	Cell = Form.CurrentScanningLine.Cell;
	
	If Not Object.UseOrderSupplyWithAssignment
		Or ThisIsAPackingList(Form.CurrentScanningLine)
		Or ThisIsUnknownBarcode(Form.CurrentScanningLine) Then
		Return;
	EndIf;
	
	If ModeSettings.JobType = "Filter"
		Or (Not ThisIsSetOfGoods
			And ModeSettings.JobType = "Location")
		Or ModeSettings.JobType = "Move" Then
		
		Return;
		
	EndIf;
	
	Filter = New Structure("Products, Characteristic, Package");
	FillPropertyValues(Filter, OwnGoods);
	
	DocumentGoods = Form.GoodsForScanning.Unload(, "Products, Characteristic, Purpose, Package,
		|NumberOfPackages, ZoomRatio");
	
	DocumentGoods.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	
	For Each RowOfGoods In DocumentGoods Do
		If RowOfGoods.ZoomRatio <> 0 Then
			RowOfGoods.Count = RowOfGoods.NumberOfPackages * RowOfGoods.ZoomRatio;
		Else
			RowOfGoods.Count = RowOfGoods.NumberOfPackages;
		EndIf;
	EndDo;
	
	OwnGoods.Purpose = WorkplaceOfWarehouseWorkerApplicationInterface.SelectAppointment(Object.Warehouse,
		Object.ReferenceOrder, Cell, OwnGoods, DocumentGoods, ModeSettings);
	
	Form.CurrentScanningLine.Purpose = OwnGoods.Purpose;
	
	SetDestinationHeader(Form);
	
EndProcedure

// Jumps to the line with the specified product.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
Procedure GoToProductLineByProduct(Form, OwnGoods)
	
	GoodsForScanning = Form.GoodsForScanning;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	FilterParameters = New Structure("Products, Characteristic, Purpose, Package");
	FillPropertyValues(FilterParameters, OwnGoods);
	
	RowsArray = GoodsForScanning.FindRows(FilterParameters);
	If RowsArray.Count() =0 Then
		RowIndex = 0;
	Else
		RowIndex = GoodsForScanning.IndexOf(RowsArray[0]);
	EndIf;
	
	ScanLine = GoodsForScanning[RowIndex];
	
	CellHasNotChanged = (CurrentScanningLine.SKCell = ScanLine.Cell);
	
	ProductsHaveNotChanged = (CurrentScanningLine.SKProducts = ScanLine.Products) 
		And (CurrentScanningLine.SCCharacteristics = ScanLine.Characteristic)
		And (CurrentScanningLine.SkPackaging = ScanLine.Package);
	
	CurrentScanningLine = ScanLine();
	
	ResetMarkOfActiveLineOfScanItems(GoodsForScanning);
	SetScanLineActivity(ScanLine);
	
	FillPropertyValues(CurrentScanningLine, ScanLine);
	
	CurrentScanningLine.SKCell = ?(CellHasNotChanged, CurrentScanningLine.Cell, Catalogs.StorageBins.EmptyRef());
	CurrentScanningLine.SKProducts = ?(ProductsHaveNotChanged, CurrentScanningLine.Products, Catalogs.Products.EmptyRef());
	CurrentScanningLine.SCCharacteristics = ?(ProductsHaveNotChanged, CurrentScanningLine.Characteristic, Catalogs.ItemsCharacteristics.EmptyRef());
	CurrentScanningLine.SkPackaging = ?(ProductsHaveNotChanged, CurrentScanningLine.Package, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	ResetSignsOfScanningAllParameters(Form);
	SetParameterScanFlag(Form, "Cell", Not CellHasNotChanged);
	SetParameterScanFlag(Form, "Products", Not ProductsHaveNotChanged);
	
	Form.CurrentScanningLine = CurrentScanningLine;
	
EndProcedure

// Returns the status of specifying a series for the case of a set of products.
//
// Parameters:
//	Products - CatalogRef.Products - Nomenclature.
//	Warehouse - CatalogRef.Warehouses - warehouse.
//	Premise - CatalogRef.Warerooms - warehouse.
//	Job - DocumentRef.GoodsReceiptNote, DocumentRef.GoodsIssueNote, DocumentRef.GoodsPickingPlacement, DocumentRef.InventoryRecount - a warehouse task that is being accepted for work.
//	JobType - String - type of warehouse task.
//
// Returns:
//	Number - the status of the indication of the product series.
//
Function StatusOfSeriesIndication(Products, Warehouse, Premise, Job, JobType)
	
	TypeProducts = New TypeDescription("CatalogRef.Products");
	TypeOfProductCharacteristics = New TypeDescription("CatalogRef.ItemsCharacteristics");
	TypeOfProductPackaging = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	NumberType = New TypeDescription("Number");
	TypeSeries = New TypeDescription("CatalogRef.ItemsBatches");
	TypePackingList = New TypeDescription("DocumentRef.PackingList");
	TypeRTiU = New TypeDescription("DocumentRef.CustomerInvoice");
	TypePurpose = New TypeDescription("CatalogRef.Assignments");
	
	Goods = New ValueTable;
	Goods.Columns.Add("LineNumber", NumberType);
	Goods.Columns.Add("Products", TypeProducts);
	Goods.Columns.Add("Characteristic", TypeOfProductCharacteristics);
	Goods.Columns.Add("Package", TypeOfProductPackaging);
	Goods.Columns.Add("BatchesIndicationStatus", NumberType);
	Goods.Columns.Add("Count", NumberType);
	Goods.Columns.Add("NumberOfPackages", NumberType);
	Goods.Columns.Add("DoNotShip", NumberType);
	Goods.Columns.Add("DocumentShipments", TypeRTiU);
	Goods.Columns.Add("PackingListParent", TypePackingList);
	Goods.Columns.Add("PackingList", TypePackingList);
	Goods.Columns.Add("Purpose", TypePurpose);
	Goods.Columns.Add("Series", TypeSeries);
	
	NewRow = Goods.Add();
	NewRow.LineNumber = 1;
	NewRow.Products = Products;
	
	If JobType = "Receiving" Then
		
		Object = New Structure();
		Object.Insert("Warehouse", Warehouse);
		Object.Insert("Premise", Premise);
		Object.Insert("Goods", Goods);
		Object.Insert("Status", Enums.GoodsReceiptNoteStatuses.Accepted);
		Object.Insert("WarehouseOperation", Common.ObjectAttributeValue(Job, "WarehouseOperation"));
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptNote));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		StatusOfSeriesIndication = Goods[0].BatchesIndicationStatus;
		
	ElsIf JobType = "Location" Then
		
		Object = New Structure();
		Object.Insert("Warehouse", Warehouse);
		Object.Insert("Premise", Premise);
		Object.Insert("GoodsPlacement", Goods);
		Object.Insert("OperationKind", Enums.OperationKindsOfGoodsPlacementPicking.Location);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsPickingPlacement);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Location);
		
		StatusOfSeriesIndication = Goods[0].BatchesIndicationStatus;
		
	ElsIf JobType = "Recalculate" Then
		
		Object = New Structure();
		Object.Insert("Warehouse", Warehouse);
		Object.Insert("Premise", Premise);
		Object.Insert("Goods", Goods);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryRecount);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		StatusOfSeriesIndication = Goods[0].BatchesIndicationStatus;
		
	ElsIf JobType = "PickingCheck" Then
		
		StructureOfTaskDetails = Common.ObjectAttributesValues(Job,
			"WarehouseOperation, DateOfShipment");
		
		Object = New Structure();
		Object.Insert("Warehouse", Warehouse);
		Object.Insert("Premise", Premise);
		Object.Insert("ShippedGoods", Goods);
		Object.Insert("Status", Enums.GoodsIssueNoteStatuses.ToShip);
		Object.Insert("WarehouseOperation", StructureOfTaskDetails.WarehouseOperation);
		Object.Insert("DateOfShipment", StructureOfTaskDetails.DateOfShipment);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.GoodsQuantityCheckInDocument);
		
		SeriesSpecificationParameters.NameTSGoods = "ShippedGoods";
		SeriesSpecificationParameters.TSSeriesName = "ShippedGoods";
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		StatusOfSeriesIndication = Goods[0].BatchesIndicationStatus;
		
	EndIf;
	
	Return StatusOfSeriesIndication;
	
EndFunction

// Called when scanning or manually entering the product's barcode.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ProductBarcode - String - the barcode of the product.
//	OwnGoods - Undefined - the variable in which to store the structure of the product,
//	HasErrors - Undefined - the variable that the error flag is written to.
//
Procedure WhenScanningItem(Form, ProductBarcode, OwnGoods, HasErrors)
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	ProcessingProcedure_ = ModeSettings.ProcessingProcedure_;
	SelectionScanned = ModeSettings.SelectionScanned;
	
	BarcodeFound = False;
	GoodsForScanning = Form.GoodsForScanning;
	
	WHBarcodes = WHBarcodes(Form);
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(ProcessingProcedure_);
	PackingListsCanBeUsedInJob = PackingListsCanBeUsedInJob(JobType);
	
	If JobType = "Filter"
		Or (JobType = "Location"
			And Not ThisIsSetOfGoods)
		Or JobType = "Move" Then
		
		OwnGoods = OwnGoods();
		
		For Each RowOfProduct In GoodsForScanning Do
			
			If Not ValueIsFilled(RowOfProduct.ItemsBarcode) Then
				Continue;
			EndIf;
			
			ProductBarcode = InformationRegisters.ItemsBarcodes.PrepareBarcode(ProductBarcode);
			
			If (StrLen(ProductBarcode) > 1)
				And StrFind(RowOfProduct.ItemsBarcode, ProductBarcode) > 0 Then
				
				FillPropertyValues(OwnGoods, RowOfProduct);
				
				BarcodeFound = True;
				OwnGoods.Barcode = ProductBarcode;
				
				Break;
				
			EndIf;
			
		EndDo;
		
		If Not BarcodeFound Then
			HasErrors = True;
			OwnGoods.ErrorType = "ProductNotFound";
		EndIf;
		
	Else
		
		OwnGoods = WorkplaceOfWarehouseWorkerApplicationInterface.FindProductOrPackingList(ProductBarcode,
			PackingListsCanBeUsedInJob);
		
		If OwnGoods.ReturnCode = 0 Then
			If WHBarcodes
				And OwnGoods.ErrorType = "ProductNotFound" Then
				
				Form.ModeSettings.DisplayWarningWhenScanning = True;
				Form.ModeSettings.MessageID_ = "WarningUnknownBarcode";
				
			Else
				HasErrors = True;
			EndIf;
		EndIf;
		
		If OwnGoods.ThisIsAPackingList Then
			HasErrors = Not CheckPackingList(Form, OwnGoods);
		EndIf;
		
	EndIf;
	
	If HasErrors
		Or ThisIsSetOfGoods Then
		Return;
	EndIf;
	
	SeriesAreSpecified = ValueIsFilled(Form.CurrentScanningLine.Series);
	
	If JobType = "Filter" Then
		
		If Not ItemMatchesScanLineItem(Form.CurrentScanningLine, OwnGoods) Then
			HasErrors = True;
		EndIf;
		
	ElsIf JobType = "Location" Then
		
		If Not ProductIsInTask(Form, OwnGoods) Then
			HasErrors = True;
		Else
			
			If ThisIsProcessingOrderOfItemCell Then
				
				If Not SeriesAreSpecified Then
					If Not ProductIsAvailableForScanning(Form, OwnGoods) Then
						HasErrors = True;
					EndIf;
				EndIf;
				
			Else
				
				If Not ItemMatchesScanLineItem(Form.CurrentScanningLine, OwnGoods) Then
					HasErrors = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	ElsIf JobType = "Move" Then
		
		If SelectionScanned
			And ThisIsProcessingOrderOfItemCell Then
			
			If Not ProductIsInTask(Form, OwnGoods) Then
				HasErrors = True;
				Return;
			EndIf;
			
			If Not SeriesAreSpecified Then
				If Not ProductIsAvailableForScanning(Form, OwnGoods) Then
					HasErrors = True;
				EndIf;
			EndIf;
			
		Else
			If Not ItemMatchesScanLineItem(Form.CurrentScanningLine, OwnGoods) Then
				HasErrors = True;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Called after scanning or manually entering the barcode of the cell.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Cell - CatalogRef.StorageBins - storage cell.
//	HasErrors - Boolean - variable for the error flag.
//
Procedure AfterScanningCell(Form, Cell, HasErrors)
	
	If HasErrors Then
		Return;
	EndIf;
	
	ModeSettings = Form.ModeSettings;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If ThisIsSetOfGoods Then // Scanned the cell of the acceptance zone.
		Form.CurrentScanningLine.SKCell = Cell;
		ModeSettings.ReceivingArea = Cell;
	Else
		Form.CurrentScanningLine.SKCell = Cell;
	EndIf;
	
	If JobType = "Filter" Then
		SetParameterScanFlag(Form, "Products", True);
		GoToNextScanOption(Form);
	ElsIf JobType = "Location" Then
		If Not ThisIsSetOfGoods
			And ThisIsProcessingOrderOfItemCell Then
			
			If Not ModeSettings.Mode = "EnterQuantity" Then
				CurrentScanningLine.NumberOfPackagingsScanned = 
					CurrentScanningLine.NumberOfPackagingsScanned + CurrentScanningLine.NumberOfPackagesToPut;
				
				SetScannedQuantityOfGoods(Form);
				SwitchToProductScanStandbyMode(Form);
				GoToNextScanOption(Form);
			EndIf;
			
		Else
			ResetSignsOfScanningAllParameters(Form);
			SetParameterScanFlag(Form, "Products", True);
			GoToNextScanOption(Form);
		EndIf;
	ElsIf JobType = "Move" Then
		If ThisIsProcessingOrderOfItemCell 
			And SelectionScanned Then
			
			If Not ModeSettings.Mode = "EnterQuantity" Then
				CurrentScanningLine.NumberOfPackagingsScanned = 
					CurrentScanningLine.NumberOfPackagingsScanned + 
					CurrentScanningLine.NumberOfPackagesToPut;
				
				SetScannedQuantityOfGoods(Form);
				SwitchToProductScanStandbyMode(Form);
			EndIf;
			
		Else
			ResetSignsOfScanningAllParameters(Form);
			SetParameterScanFlag(Form, "Products", True);
			GoToNextScanOption(Form);
		EndIf;
	ElsIf JobType = "Recalculate" Then
		ResetSignsOfScanningAllParameters(Form);
		SetParameterScanFlag(Form, "Products", True);
		GoToNextScanOption(Form);
	EndIf;
	
EndProcedure

// Invoked when the scan, or manually enter the barcode of the cell.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	CellBarcode - String - barcode of the cell.
//	Cell - Undefined - the variable in which to store the information about the found cell.
//	HasErrors - Boolean - variable for the error flag.
//	ThisIsScan - Boolean
//
Procedure WhenScanningCell(Form, CellBarcode, Cell, HasErrors, ThisIsScan)
	
	Object = Form.Object;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	GoodsForScanning = Form.GoodsForScanning;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	CellBarcode = TrimAll(CellBarcode);
	
	If JobType = "Filter"
		Or (JobType = "Location"
			And Not ThisIsSetOfGoods)
		Or JobType = "Move"
		Or JobType = "Recalculate" Then
		
		Filter = New Structure("CellBarcode", CellBarcode);
		RowsArray = GoodsForScanning.FindRows(Filter);
		
		If RowsArray.Count() = 0 Then
			
			For Each RowOfGoods In GoodsForScanning Do
				If Upper(RowOfGoods.CellCode) = Upper(CellBarcode) Then
					Cell = RowOfGoods.Cell;
					Break;
				EndIf;
			EndDo;
			
			If Not ValueIsFilled(Cell) Then
				HasErrors = True;
			EndIf;
		Else
			Cell = RowsArray[0].Cell
		EndIf;
		
	Else
		
		CellParameters_ = WorkplaceOfWarehouseWorkerApplicationInterface.FindCellByBarcode(Object.Warehouse,
			Object.Premise, CellBarcode, ThisIsScan);
		
		If CellParameters_.ReturnCode = 0 Then
			HasErrors = True;
		Else
			Cell = CellParameters_.Cell;
		EndIf;
		
	EndIf;
	
	If HasErrors Then
		Return;
	EndIf;
	
	ArrayOfCellTypes = New Array;
	CommonClientServer.SupplementArray(ArrayOfCellTypes, WarehousesClientServer.CellTypesAcceptance());
	CommonClientServer.SupplementArray(ArrayOfCellTypes, WarehousesClientServer.CellTypesShipment());
	
	If ThisIsSetOfGoods Then
		
		If ArrayOfCellTypes.Find(CellParameters_.CellType) = Undefined Then
			HasErrors = True;
		EndIf;
		
	Else
		
		If Not CellIsSameAsCellOfScanLine(Form.CurrentScanningLine, Cell) Then
			HasErrors = True;
		EndIf;
		
	EndIf;
	
EndProcedure

// Called after scanning (or manually entering the barcode series).
// Depending on the type of job processing is introduced in the series.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Series - See ProductSeries
//	HasErrors - Boolean - error flag.
//
Procedure AfterScanningSeries(Form, Series, HasErrors)
	
	If HasErrors Then
		Return;
	EndIf;
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	SelectionScanned = ModeSettings.SelectionScanned;
	SeriesScanMode = Form.SeriesScanMode;
	CurrentScanningLine = Form.CurrentScanningLine;
	BatchesIndicationStatus = CurrentScanningLine.BatchesIndicationStatus;
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	SeriesAreSpecifiedForReference = SeriesAreSpecifiedForReference(CurrentScanningLine.BatchesIndicationStatus);
	
	OwnGoods = OwnGoods();
	FillPropertyValues(OwnGoods, CurrentScanningLine);
	FillPropertyValues(OwnGoods, Series);
	
	SelectAppointment(Form, OwnGoods);
	FillInProductWeightByBarcode(OwnGoods);
	
	If ThisIsSetOfGoods
		Or JobType = "Recalculate"
		Or JobType = "PickingCheck" Then
		
		If JobType = "Recalculate" Then
			
			CurrentScanningLine.Series = Series.Series;
			CurrentScanningLine.SkSeries = Series.Series;
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				SetScannedNumberOfPackages(Form, 1);
				AddToScannedProducts(Form);
				
			Else
				If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
					SetScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
					AddToScannedProducts(Form);
				Else
					ScanToEnterTheNumber(Form);
					Return;
				EndIf;
			EndIf;
			
			ResetSignsOfScanningAllParameters(Form);
			
			If SeriesScanMode = "ProductSeriesProduct" Then
				SetParameterScanFlag(Form, "Products", True);
			Else
				SetParameterScanFlag(Form, "Series", True);
			EndIf;
			
			GoToNextScanOption(Form);
			
		ElsIf JobType = "PickingCheck" Then
			
			If Not (ItemMatchesScanLineItem(CurrentScanningLine, OwnGoods)
					And (CurrentScanningLine.Purpose = OwnGoods.Purpose))
				Or Not SeriesIsSameAsScanLineSeries(CurrentScanningLine, Series.Series) Then
				
				If SeriesAreSpecifiedForReference
					And SeriesIdentifiesItemInstance(OwnGoods) Then
					
					If (ItemMatchesScanLineItem(CurrentScanningLine, OwnGoods)
							Or ProductIsInTask(Form, OwnGoods))
						And CheckAddReferenceSeriesToProductsForScanning(Form, OwnGoods, Series.Series) Then
						
						GoToProductLineWithSeries(Form, OwnGoods);
						
					ElsIf Not ReferenceSeriesIsUnique(Form, Series) Then
						
						GoToProductLineWithSeries(Form, OwnGoods);
						
					Else
						FillPropertyValues(CurrentScanningLine, ScanLine());
						FillPropertyValues(CurrentScanningLine, OwnGoods);
						
						CurrentScanningLine.BatchesIndicationStatus = BatchesIndicationStatus;
						
						If ReferenceSeriesIsUnique(Form, Series) Then
							SetScannedNumberOfPackages(Form, 0);
						EndIf;
					EndIf;
					
				Else
					
					If ProductSeriesIsInTask(Form, OwnGoods, Series.Series) Then
						GoToProductLineWithSeries(Form, OwnGoods);
					Else
						FillPropertyValues(CurrentScanningLine, ScanLine());
						FillPropertyValues(CurrentScanningLine, OwnGoods);
						CurrentScanningLine.BatchesIndicationStatus = BatchesIndicationStatus;
						
						SetScannedNumberOfPackages(Form, 0);
					EndIf;
					
				EndIf;
				
			ElsIf SeriesAreSpecifiedForReference
				And SeriesIdentifiesItemInstance(OwnGoods) Then
				
				ReferenceSeriesIsUnique(Form, Series);
				
			EndIf;
			
			FillInPropertyValuesOfScannedProduct(CurrentScanningLine, OwnGoods);
			CurrentScanningLine.Series = Series.Series;
			CurrentScanningLine.SkSeries = Series.Series;
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
					
				If ModeSettings.MessageID_ <> "ErrorSeriesIsNotUnique" Then
					SetScannedNumberOfPackages(Form, 1);
					AddToScannedProducts(Form);
				EndIf;
				
			Else
				
				If ModeSettings.MessageID_ <> "ErrorSeriesIsNotUnique" Then
					
					If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
						SetScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
						AddToScannedProducts(Form);
					Else
						ScanToEnterTheNumber(Form);
						Return;
					EndIf;
				EndIf;
				
			EndIf;
			
			If SeriesScanMode = "ProductSeriesProduct" Then
				SetParameterScanFlag(Form, "Products", True);
				GoToNextScanOption(Form);
			EndIf;
			
		ElsIf JobType = "Receiving" Then
			
			If Form.ModeSettings.ScanParameter = "Products" Then
				Return;
			EndIf;
			
			If SeriesAreSpecifiedForReference
				And SeriesIdentifiesItemInstance(CurrentScanningLine) Then
				
				ReferenceSeriesIsUnique(Form, Series);
				
			EndIf;
			
			If ModeSettings.MessageID_ = "ErrorSeriesIsNotUnique" Then
				Filter = New Structure("Products, Characteristic, Purpose, Package, Series");
				
				FillPropertyValues(Filter, CurrentScanningLine, , "Series");
				FillPropertyValues(Filter, Series);
				
				RowsArray = Form.ScannedGoods.FindRows(Filter);
				
				If RowsArray.Count() > 0 Then
					FillPropertyValues(CurrentScanningLine, RowsArray[0], "NumberOfPackagingsScanned");
				EndIf;
			EndIf;
			
			CurrentScanningLine.Series = Series.Series;
			CurrentScanningLine.SkSeries = Series.Series;
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				If ModeSettings.MessageID_ <> "ErrorSeriesIsNotUnique" Then
					SetScannedNumberOfPackages(Form, 1);
					AddToScannedProducts(Form);
				EndIf;
				
			Else
				
				If ModeSettings.MessageID_ <> "ErrorSeriesIsNotUnique" Then
					
					If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
						SetScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
						AddToScannedProducts(Form);
					Else
						ScanToEnterTheNumber(Form);
						Return;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If SeriesScanMode = "ProductSeriesProduct" Then
				GoToNextScanOption(Form);
			EndIf;
			
		ElsIf JobType = "Location" Then
			
			CurrentScanningLine.Series = Series.Series;
			CurrentScanningLine.SkSeries = Series.Series;
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				SetScannedNumberOfPackages(Form, 1);
				AddToScannedProducts(Form);
				
			Else
				
				If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
					SetScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
					AddToScannedProducts(Form);
				Else
					ScanToEnterTheNumber(Form);
					Return;
				EndIf;
				
			EndIf;
			
			ResetSignsOfScanningAllParameters(Form);
			
			SetParameterScanFlag(Form, "Cell", ValueIsFilled(ModeSettings.DefaultAcceptanceZone));
			SetParameterScanFlag(Form, "Products", True);
			
			If SeriesScanMode = "ProductSeriesProduct" Then
				GoToNextScanOption(Form);
			EndIf;
			
		EndIf;
		
	ElsIf JobType = "Location" Then
		
		FillPropertyValues(CurrentScanningLine, Series);
		CurrentScanningLine.SkSeries = Series.Series;
		
		If ThisIsProcessingOrderOfItemCell Then
			
			OwnGoods = OwnGoods();
			FillPropertyValues(OwnGoods, CurrentScanningLine);
			GoToProductLineWithSeries(Form, OwnGoods);
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				SetScannedNumberOfPackages(Form, 1);
				SetScannedQuantityOfGoods(Form);
				
			Else
				
				If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
					If BarcodeQuantityIsCorrect(Form) Then
						SetScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
						SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
					EndIf;
				Else
					ScanToEnterTheNumber(Form);;
				EndIf;
				
			EndIf;
			
		Else
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				IncreaseScannedNumberOfPackages(Form, 1);
				SetScannedQuantityOfGoods(Form);
				
			Else
				
				If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
					If BarcodeQuantityIsCorrect(Form) Then
						IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
						SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
					EndIf;
				Else
					ScanToEnterTheNumber(Form);
					Return;
				EndIf;
				
			EndIf;
			
			If SeriesScanMode = "ProductSeriesProduct" Then
				SetParameterScanFlag(Form, "Products", True);
				GoToNextScanOption(Form);
			EndIf;
			
		EndIf;
		
	ElsIf JobType = "Move" Then
		
		FillPropertyValues(CurrentScanningLine, Series);
		CurrentScanningLine.SkSeries = Series.Series;
		CurrentScanningLine.SKSeriesNumber = Series.BatchNumber;
		CurrentScanningLine.SKIsGoodTo = Series.ValidUntil_;
		
		If SelectionScanned
			And ThisIsProcessingOrderOfItemCell Then
			
			OwnGoods = OwnGoods();
			FillPropertyValues(OwnGoods, CurrentScanningLine);
			GoToProductLineWithSeries(Form, OwnGoods);
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				SetScannedNumberOfPackages(Form, 1);
				SetScannedQuantityOfGoods(Form);
				
			Else
				
				If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
					If BarcodeQuantityIsCorrect(Form) Then
						SetScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
						SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
					EndIf;
				Else
					ScanToEnterTheNumber(Form);
				EndIf;
				
			EndIf;
			
		Else
			
			If ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
				
				IncreaseScannedNumberOfPackages(Form, 1);
				SetScannedQuantityOfGoods(Form);
				
			Else
				
				If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
					If BarcodeQuantityIsCorrect(Form) Then
						IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
						SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
					EndIf;
				Else
					ScanToEnterTheNumber(Form);
					Return;
				EndIf;
				
			EndIf;
			
			If SeriesScanMode = "ProductSeriesProduct" Then
				SetParameterScanFlag(Form, "Products", True);
				GoToNextScanOption(Form);
			EndIf;
			
		EndIf;
		
	ElsIf JobType = "Filter" Then
		
		FillPropertyValues(CurrentScanningLine, Series);
		CurrentScanningLine.SkSeries = Series.Series;
		CurrentScanningLine.SKSeriesNumber = Series.BatchNumber;
		CurrentScanningLine.SKIsGoodTo = Series.ValidUntil_;
		
		If ValueIsFilled(Form.CurrentScanningLine.Package)
			Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
				And DimensionalUnitsOfMeasurement.Find(Form.CurrentScanningLine.MeasuredValueType) = Undefined) Then
			
			IncreaseScannedNumberOfPackages(Form, 1);
			SetScannedQuantityOfGoods(Form);
			
		Else
			
			If ValueIsFilled(Form.CurrentScanningLine.QuantityByBarcode) Then
				If BarcodeQuantityIsCorrect(Form) Then
					IncreaseScannedNumberOfPackages(Form, Form.CurrentScanningLine.QuantityByBarcode);
					SetScannedQuantityOfGoods(Form, , Form.CurrentScanningLine.QuantityByBarcode);
				EndIf;
			Else
				ScanToEnterTheNumber(Form);
				Return;
			EndIf;
			
		EndIf;
		
		If SeriesScanMode = "ProductSeriesProduct" Then
			SetParameterScanFlag(Form, "Products", True);
			GoToNextScanOption(Form);
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns a structure for storing information about the series.
//
// Returns:
// 	Structure - description of a series of items that contains the following fields:
//	* ValidUntil_ - Date - shelf life of the series.
//	* BatchNumber - String - serial number.
//	* Series - CatalogRef.ItemsBatches - link to a series of items in the information base.
//
Function ProductSeries()
	
	SeriesStructure = New Structure;
	SeriesStructure.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	SeriesStructure.Insert("BatchNumber", "");
	SeriesStructure.Insert("ValidUntil_", Date("00010101"));
	
	Return SeriesStructure;
	
EndFunction

// Invoked when the scan, or manually enter the barcode of the series.
// Checks whether the batch ID (number, expiration date, or number+expiration date) is correct.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	BarcodeSeries - String - barcode of the series.
//	SeriesShelfLife - Date - shelf life of the series,.a link to the found series is provided.
//	Series - See ProductSeries
//	HasErrors - Undefined - error flag.
//
Procedure WhenScanningSeries(Form, BarcodeSeries, SeriesShelfLife, Series, HasErrors)
	
	Var ExpirationDate_;
	Series = ProductSeries();
	
	Mode = Form.ModeSettings.Mode;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	SelectionScanned = ModeSettings.SelectionScanned;
	
	WHBarcodes = WHBarcodes(Form);
	CurrentScanningLine = Form.CurrentScanningLine;
	
	SeriesIndicationParameters = New Structure("SpecifyNumberWhenRegisteringBatch, UseShelfLifeOnBatchRegistration,
		|PrecisionOfBatchShelfLifeIndication");
	FillPropertyValues(SeriesIndicationParameters, CurrentScanningLine);
	
	If ThisIsSetOfGoods
		Or JobType = "Receiving"
		Or JobType = "Recalculate"
		Or JobType = "PickingCheck" Then
		
		ThisIsScan = Mode = "EnterValue";
		
		SeriesParameters = WorkplaceOfWarehouseWorkerApplicationInterface.FindSeries_(BarcodeSeries, SeriesShelfLife,
			CurrentScanningLine.ProductKind, SeriesIndicationParameters, ThisIsScan);
		
		If SeriesParameters.ReturnCode = 0 Then
			
			If WHBarcodes
				And Not SeriesIndicationParameters.UseShelfLifeOnBatchRegistration
				And ValueIsFilled(Form.CurrentScanningLine.Package)
				Or (Not ValueIsFilled(Form.CurrentScanningLine.Package)
					And Not ThisIsTara(Form.CurrentScanningLine)
					And Not (Form.CurrentScanningLine.MeasuredValueType = Enums.TypesOfMeasuredValues.Weight
						Or Form.CurrentScanningLine.MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3
						Or Form.CurrentScanningLine.MeasuredValueType = Enums.TypesOfMeasuredValues.Length
						Or Form.CurrentScanningLine.MeasuredValueType = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement)) Then
				
				Form.ModeSettings.ScanParameter = "Products";
				WhenScanningValue(Form, BarcodeSeries);
				
			Else
				HasErrors = True;
			EndIf;
			
			Return;
			
		EndIf;
		
		FillPropertyValues(Series, SeriesParameters);
		
	Else
		
		If Mode = "EnterValue" Then
			
			BatchNumber = TrimAll(BarcodeSeries);
			
			If ValueIsFilled(SeriesShelfLife) Then
				
				If Not ShelfLifeOfSeriesIsCorrect(SeriesIndicationParameters, SeriesShelfLife, ExpirationDate_) Then
					HasErrors = True;
					Return;
				EndIf;
				
			Else
				ExpirationDate_ = Date("00010101");
			EndIf;
			
		Else
			
			SeriesInformation = WorkplaceOfWarehouseWorkerApplicationInterface.SeriesInformationFromBarcode(BarcodeSeries,
				SeriesIndicationParameters.SpecifyNumberWhenRegisteringBatch, SeriesIndicationParameters.UseShelfLifeOnBatchRegistration);
			
			If SeriesInformation.HasError Then
				HasErrors = True;
				Return;
			EndIf;
			
			BatchNumber = SeriesInformation.Number;
			ExpirationDate_ = SeriesInformation.ValidUntil_;
			
		EndIf;
		
		Series.BatchNumber = BatchNumber;
		Series.ValidUntil_ = ExpirationDate_;
		
		If JobType = "Filter" Then
			
			If Not (Form.CurrentScanningLine.BatchNumber = BatchNumber
					And Form.CurrentScanningLine.ValidUntil_ = ExpirationDate_)
				And Not SeriesAreIndicatedUponSelection(Form.CurrentScanningLine.BatchesIndicationStatus) Then
				HasErrors = True;
				Return;
			EndIf;
			
			Series.Series = Form.CurrentScanningLine.Series;
			
		ElsIf JobType = "Location" Then
			
			If Not (Form.CurrentScanningLine.BatchNumber = BatchNumber
					And Form.CurrentScanningLine.ValidUntil_ = ExpirationDate_) Then
				HasErrors = True;
				Return;
			EndIf;
			
			Series.Series = Form.CurrentScanningLine.Series;
			
		ElsIf JobType = "Move" Then
			
			If Not SelectionScanned Then
				If Not (Form.CurrentScanningLine.BatchNumber = BatchNumber
						And Form.CurrentScanningLine.ValidUntil_ = ExpirationDate_)
					And Not SeriesAreIndicatedUponSelection(Form.CurrentScanningLine.BatchesIndicationStatus) Then
					HasErrors = True;
					Return;
				EndIf;
			Else
				If Not (Form.CurrentScanningLine.BatchNumber = BatchNumber
						And Form.CurrentScanningLine.ValidUntil_ = ExpirationDate_) Then
					HasErrors = True;
					Return;
				EndIf;
			EndIf;
			
			Series.Series = Form.CurrentScanningLine.Series;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns an indication that the series are specified after selection (managing balances).
//
// Parameters:
//	BatchesIndicationStatus - Number - the status of specifying the series.
//
// Returns:
//	Boolean - flag indicating the series upon selection.
//
Function SeriesAreIndicatedUponSelection(BatchesIndicationStatus)
	
	ArrayOfStatuses = New Array;
	ArrayOfStatuses.Add(3);
	ArrayOfStatuses.Add(4);
	
	Return Not (ArrayOfStatuses.Find(BatchesIndicationStatus) = Undefined);
	
EndFunction

// Returns an indication that the series are specified for reference (when shipping after selection).
//
// Parameters:
//	BatchesIndicationStatus - Number - the status of specifying the series.
//
// Returns:
//	Boolean - the flag of the series indication is for reference.
//
Function SeriesAreSpecifiedForReference(BatchesIndicationStatus)
	
	ArrayOfStatuses = New Array;
	ArrayOfStatuses.Add(1);
	ArrayOfStatuses.Add(2);
	
	Return Not (ArrayOfStatuses.Find(BatchesIndicationStatus) = Undefined);
	
EndFunction

// Returns an indication that the series is specified.
//
// Parameters:
//	BatchesIndicationStatus - Number - the status of specifying the series.
//
// Returns:
//	Boolean - the flag of the need to specify the series.
//
Function SeriesAreSpecified(BatchesIndicationStatus)
	
	ArrayOfStatuses = New Array;
	ArrayOfStatuses.Add(0);
	ArrayOfStatuses.Add(11);
	ArrayOfStatuses.Add(12);
	ArrayOfStatuses.Add(15);
	
	Return (ArrayOfStatuses.Find(BatchesIndicationStatus) = Undefined);
	
EndFunction

// Sets the error flag when more than necessary items were scanned during the selection check.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetProductSelectedOverorderFlag(Form)
	
	CachedValues = Form.ModeSettings.CachedValues;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ProductSelectedOverorder = False;
	
	If CachedValues = Undefined Then
		If CurrentScanningLine.NumberOfPackagesDoNotShip > 0 Then
			ProductSelectedOverorder = True;
		Else
			Return;
		EndIf;
	ElsIf CurrentScanningLine.NumberOfPackagesDoNotShip > CachedValues.NumberOfPackagesDoNotShip Then
		ProductSelectedOverorder = True;
	EndIf;
	
	If ProductSelectedOverorder
		And Not Form.ModeSettings.DisplayWarningWhenScanning Then
		Form.ModeSettings.DisplayWarningWhenScanning = True;
		Form.ModeSettings.MessageID_ = "WarningProductSelectedOverorder";
	EndIf;
	
EndProcedure

// Increases the scanned number of packages depending on the task type and 
// current mode.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Count - Number - the value to increase the scanned quantity by.
//
Procedure IncreaseScannedNumberOfPackages(Form, Count)
	
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If (Not ThisIsSetOfGoods
			And JobType = "Location"
			And ThisIsProcessingOrderOfItemCell)
		Or (JobType = "Move"
			And SelectionScanned
			And ThisIsProcessingOrderOfItemCell) Then
		
		CurrentScanningLine.NumberOfPackagesToPut = CurrentScanningLine.NumberOfPackagesToPut + Count;
		
	ElsIf JobType = "PickingCheck" Then
		CurrentScanningLine.NumberOfPackagingsScanned =
			CurrentScanningLine.NumberOfPackagingsScanned + Count;
		CurrentScanningLine.NumberOfPackagesDoNotShip = AdjustedNumberOfPackagesDoNotShip(
			CurrentScanningLine, PermissibleDeviationOfSelectedGoods);
		
		SetProductSelectedOverorderFlag(Form);
	Else
		CurrentScanningLine.NumberOfPackagingsScanned = CurrentScanningLine.NumberOfPackagingsScanned + Count;
	EndIf;
	
EndProcedure

// Sets the scanned number of packages depending on the task type and 
// current mode.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Count - Number - the value to which you want to set the scan number.
//
Procedure SetScannedNumberOfPackages(Form, Count)
	
	JobType = Form.ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If JobType = "Location"
		And ThisIsProcessingOrderOfItemCell Then
		
		CurrentScanningLine.NumberOfPackagesToPut = Count;
		
	ElsIf JobType = "Move"
		And ThisIsProcessingOrderOfItemCell
		And SelectionScanned Then
		
		CurrentScanningLine.NumberOfPackagesToPut = Count;
		
	ElsIf JobType = "PickingCheck" Then
		CurrentScanningLine.NumberOfPackagingsScanned = Count;
		CurrentScanningLine.NumberOfPackagesDoNotShip = AdjustedNumberOfPackagesDoNotShip(
			CurrentScanningLine, PermissibleDeviationOfSelectedGoods);
		
		SetProductSelectedOverorderFlag(Form);
	Else
		CurrentScanningLine.NumberOfPackagingsScanned = Count;
	EndIf;
	
EndProcedure

// Called after entering the number of products. The task of the procedure is to process
// the specified quantity if the value passed the validation check.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Count - Number - the scanned quantity.
//	HasErrors - Boolean - error flag.
//
Procedure AfterEnteringQuantity(Form, Count, HasErrors)
	
	If HasErrors Then
		Form.TheCurrentSeriesScanParameter = False;
		Return;
	EndIf;
	
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	ModeSettings = Form.ModeSettings;
	JobType = Form.ModeSettings.JobType;
	Mode = Form.ModeSettings.Mode;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	SeriesAreSpecified = SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus);
	
	If ThisIsSetOfGoods
		Or JobType = "Recalculate" Then
		
		ThisIsInputAsIntended = False;
		
		If CurrentScanningLine.NewAssignment = CurrentScanningLine.Purpose Then
			
			If Mode = "EnteringQuantityAsIntended" Then
				ThisIsInputAsIntended = True;
			EndIf;
			
			Mode = "EnterQuantity";
			
		EndIf;
		
		CurrentScanningLine.NumberOfPackagingsScanned = Count;
		AddToScannedProducts(Form, ThisIsInputAsIntended);
		
		ResetSignsOfScanningAllParameters(Form);
		
		If Form.SeriesScanMode = "ProductSeriesProduct"
			Or ThisIsInputAsIntended Then
			SetParameterScanFlag(Form, "Products", True);
		Else
			If SeriesAreSpecified
				And Form.TheCurrentSeriesScanParameter Then
				
				Form.TheCurrentSeriesScanParameter = False;
				SetParameterScanFlag(Form, "Series", True);
				
			Else
				SetParameterScanFlag(Form, "Products", True);
			EndIf;
		EndIf;
		
		GoToNextScanOption(Form);
		
	Else
		If JobType = "PickingCheck" Then
			
			ThisIsInputAsIntended = False;
			
			If Mode = "EnteringQuantityNotToShip" Then
				CurrentScanningLine.NumberOfPackagesDoNotShip = Count;
				CurrentScanningLine.NumberOfPackagesDoNotShip = AdjustedNumberOfPackagesDoNotShip(
					CurrentScanningLine, PermissibleDeviationOfSelectedGoods);
				
				ModeSettings.Mode = "EnterQuantity";
			Else
				
				If CurrentScanningLine.NewAssignment = CurrentScanningLine.Purpose Then
					
					OwnGoods = ScanLine();
					FillPropertyValues(OwnGoods, CurrentScanningLine, , "ActiveString, QuantityOfGoodsInDocument,
						|QuantityNotToShip, NumberOfPackages, NumberOfPackagesInDocument, NumberOfPackagesDoNotShip");
					
					Filter = New Structure("Products, Characteristic, Purpose, Package, Series");
					FillPropertyValues(Filter, OwnGoods);
					
					RowsArray = Form.GoodsForScanning.FindRows(Filter);
					If RowsArray.Count() > 0 Then
						ProductIsInTask = True;
					Else
						ProductIsInTask = False;
					EndIf;
					
					If ProductIsInTask Then
						FillPropertyValues(Form.CurrentScanningLine, RowsArray[0]);
						ResetMarkOfActiveLineOfScanItems(Form.GoodsForScanning);
						SetScanLineActivity(RowsArray[0]);
					Else
						NumberOfProductItems = Form.CurrentScanningLine.QuantityOfGoodsInABin + 1;
						CurrentScanningLine = ScanLine();
						FillPropertyValues(Form.CurrentScanningLine, OwnGoods);
						
						Form.CurrentScanningLine.GoodsNumberInTheBin = NumberOfProductItems;
						Form.CurrentScanningLine.QuantityOfGoodsInABin = NumberOfProductItems;
						
						ModeSettings.DisplayWarningWhenScanning = True;
						ModeSettings.MessageID_ = "WarningProductMissingFromTask";
					EndIf;
					
					If Mode = "EnteringQuantityAsIntended" Then
						ThisIsInputAsIntended = True;
					EndIf;
					
					Mode = "EnterQuantity";
					
				EndIf;
				
				NumberOfPackagingsScanned = Count;
				
				SetScannedNumberOfPackages(Form, Count);
				CurrentScanningLine.NumberOfPackagesDoNotShip = AdjustedNumberOfPackagesDoNotShip(
					Form.CurrentScanningLine, PermissibleDeviationOfSelectedGoods);
				
			EndIf;
			
			AddToScannedProducts(Form, ThisIsInputAsIntended);
			
		Else
			
			NumberOfPackagingsScanned = 0;
			
			If JobType = "Location" Then
				NumberOfPackagingsScanned = Count;
				If ThisIsProcessingOrderOfItemCell Then
					CurrentScanningLine.NumberOfPackagesToPut = Count;
					SetNumberOfBalancesToProductBalancesInCell(Form);
					ResetSignsOfScanningAllParameters(Form);
					SetParameterScanFlag(Form, "Cell", True);
					Return;
				Else
					If Form.SeriesScanMode = "ProductSeriesProduct" Then
						SetParameterScanFlag(Form, "Products", True);
					Else
						If SeriesAreSpecified
							And Form.TheCurrentSeriesScanParameter Then
							
							Form.TheCurrentSeriesScanParameter = False;
							SetParameterScanFlag(Form, "Series", True);
							
						Else
							SetParameterScanFlag(Form, "Products", True);
						EndIf;
					EndIf;
					
					GoToNextScanOption(Form);
					SetScannedNumberOfPackages(Form, Count);
					SetScannedQuantityOfGoods(Form);
				EndIf;
			ElsIf JobType = "Move" Then
				If SelectionScanned
					And ThisIsProcessingOrderOfItemCell Then
					
					CurrentScanningLine.NumberOfPackagesToPut = Count;
					SetNumberOfBalancesToProductBalancesInCell(Form);
					ResetSignsOfScanningAllParameters(Form);
					SetParameterScanFlag(Form, "Cell", True);
					GoToNextScanOption(Form);
					
					Return;
					
				Else
					If CurrentScanningLine.NumberOfPackagingsScanned = Count Then
						
						SetColorsOfScanItems(Form);
						ResetSignsOfScanningAllParameters(Form);
						
						If SeriesAreSpecified
							And Form.TheCurrentSeriesScanParameter Then
							
							Form.TheCurrentSeriesScanParameter = False;
							SetParameterScanFlag(Form, "Series", True);
							
						Else
							SetParameterScanFlag(Form, "Products", True);
						EndIf;
						
						GoToNextScanOption(Form);
						
						Return;
						
					EndIf;
					
					NumberOfPackagingsScanned = Count;
					ResetSignsOfScanningAllParameters(Form);
					
					If Form.SeriesScanMode = "ProductSeriesProduct" Then
						SetParameterScanFlag(Form, "Products", True);
					Else
						If SeriesAreSpecified
							And Form.TheCurrentSeriesScanParameter Then
							
							Form.TheCurrentSeriesScanParameter = False;
							SetParameterScanFlag(Form, "Series", True);
							
						Else
							SetParameterScanFlag(Form, "Products", True);
						EndIf;
					EndIf;
					
					GoToNextScanOption(Form);
					
				EndIf;
			Else
				If CurrentScanningLine.NumberOfPackagingsScanned = Count Then
					
					SetColorsOfScanItems(Form);
					ResetSignsOfScanningAllParameters(Form);
					
					If SeriesAreSpecified
						And Form.TheCurrentSeriesScanParameter Then
						
						Form.TheCurrentSeriesScanParameter = False;
						SetParameterScanFlag(Form, "Series", True);
						
					Else
						SetParameterScanFlag(Form, "Products", True);
					EndIf;
					
					GoToNextScanOption(Form);
					
					Return;
					
				EndIf;
				
				NumberOfPackagingsScanned = Count;
				ResetSignsOfScanningAllParameters(Form);
				
				If Form.SeriesScanMode = "ProductSeriesProduct" Then
					SetParameterScanFlag(Form, "Products", True);
				Else
					If SeriesAreSpecified
						And Form.TheCurrentSeriesScanParameter Then
						
						Form.TheCurrentSeriesScanParameter = False;
						SetParameterScanFlag(Form, "Series", True);
						
					Else
						SetParameterScanFlag(Form, "Products", True);
					EndIf;
				EndIf;
				
				GoToNextScanOption(Form);
				
			EndIf;
			
			IncreasedQuantity = NumberOfPackagingsScanned - CurrentScanningLine.NumberOfPackagingsScanned;
			SetScannedNumberOfPackages(Form, NumberOfPackagingsScanned);
			SetScannedQuantityOfGoods(Form, , IncreasedQuantity);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Called when entering the number of products.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Count - Number - the scanned quantity.
//	HasErrors - Undefined - the variable that the error flag is written to.
//
Function WhenEnteringQuantity(Form, Count, HasErrors)
	
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	JobType = Form.ModeSettings.JobType;
	SelectionScanned= Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If ThisIsSetOfGoods Then
		Return Count;
	EndIf;
	
	ThisIsMeasuredCommodity = DimensionalUnitsOfMeasurement.Find(CurrentScanningLine.MeasuredValueType) <> Undefined;
	MaximumQuantityOfSelectedGoods_ = CurrentScanningLine.NumberOfPackages +
		CurrentScanningLine.NumberOfPackages * PermissibleDeviationOfSelectedGoods / 100;
	
	If JobType = "Location" Then
		If Not ThisIsSetOfGoods
			And Count > CurrentScanningLine.NumberOfPackagesInDocument Then
			
			HasErrors = True;
			
		ElsIf (CurrentScanningLine.NumberOfPackagesPut + Count) > CurrentScanningLine.NumberOfPackagesInDocument Then
			
			Count = CurrentScanningLine.NumberOfPackagesInDocument -
				CurrentScanningLine.NumberOfPackagesPut;
			
		EndIf;
	ElsIf JobType = "Move" Then
		If SelectionScanned
			And ThisIsProcessingOrderOfItemCell Then
			
			If CurrentScanningLine.NumberOfPackagesToPut > CurrentScanningLine.NumberOfPackagesInDocument Then
				HasErrors = True;
			EndIf;
			
		Else
			If Count > CurrentScanningLine.NumberOfPackages Then
				HasErrors = True;
			Else
				If SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus)
					And Count < CurrentScanningLine.NumberOfPackagingsScanned Then
					
					Filter = New Structure("Cell, Products, Characteristic, Purpose, Package");
					FillPropertyValues(Filter, CurrentScanningLine);
					
					RowsArray = Form.ScannedGoods.FindRows(Filter);
					
					BatchNumber = RowsArray[0].BatchNumber;
					ValidUntil_ = RowsArray[0].ValidUntil_;
					NumberOfDifferentSeries = 1;
					
					For Each String In RowsArray Do
						If CurrentScanningLine.SpecifyNumberWhenRegisteringBatch
							And CurrentScanningLine.UseShelfLifeOnBatchRegistration Then
							
							If String.BatchNumber <> BatchNumber
								And String.ValidUntil_ <> ValidUntil_ Then
								
								NumberOfDifferentSeries = 2;
								Break;
								
							EndIf;
							
						Else
							If String.BatchNumber <> BatchNumber
								Or String.ValidUntil_ <> ValidUntil_ Then
								
								NumberOfDifferentSeries = 2;
								Break;
								
							EndIf;
						EndIf;
					EndDo;
					
					If NumberOfDifferentSeries > 1 Then
						HasErrors = True;
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
	ElsIf JobType = "Filter" Then
		If (ThisIsMeasuredCommodity
				And Count > MaximumQuantityOfSelectedGoods_)
			Or (Not ThisIsMeasuredCommodity
				And Count > CurrentScanningLine.NumberOfPackages) Then
			
			HasErrors = True;
			
		Else
			If SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus)
				And Count < CurrentScanningLine.NumberOfPackagingsScanned Then
				
				Filter = New Structure("Cell, Products, Characteristic, Purpose, Package");
				FillPropertyValues(Filter, CurrentScanningLine);
				
				RowsArray = Form.ScannedGoods.FindRows(Filter);
				
				BatchNumber = RowsArray[0].BatchNumber;
				ValidUntil_ = RowsArray[0].ValidUntil_;
				NumberOfDifferentSeries = 1;
				
				For Each String In RowsArray Do
					If CurrentScanningLine.SpecifyNumberWhenRegisteringBatch
						And CurrentScanningLine.UseShelfLifeOnBatchRegistration Then
						
						If String.BatchNumber <> BatchNumber
							And String.ValidUntil_ <> ValidUntil_ Then
							
							NumberOfDifferentSeries = 2;
							Break;
							
						EndIf;
						
					Else
						If String.BatchNumber <> BatchNumber
							Or String.ValidUntil_ <> ValidUntil_ Then
							
							NumberOfDifferentSeries = 2;
							Break;
							
						EndIf;
					EndIf;
				EndDo;
				
				If NumberOfDifferentSeries > 1 Then
					HasErrors = True;
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
	Return Count;
	
EndFunction

// Handles the situation when a warning is displayed when a value is scanned.
// A warning is displayed, but the error flag is not raised.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure HandleWarningWhenScanningValue(Form)
	
	If Not Form.ModeSettings.DisplayWarningWhenScanning Then
		Return;
	EndIf;
	
	WarningText = CaptionTextOfFormElementTitle(Form.ModeSettings.MessageID_, Form);
	
	DisplayWarningWhenScanningValue(Form, WarningText);
	
EndProcedure

// Handles the situation when an error occurs when scanning a value,
// for example, an invalid barcode was scanned.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ScanValue - Arbitrary - the scanned value.
//	OwnGoods - Structure - structure with information about the product.
//
Procedure HandleErrorWhenScanningValue(Form, ScanValue, OwnGoods)
	
	ScanParameter = Form.ModeSettings.ScanParameter;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	SeriesAreSpecified = SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus);
	
	If ScanParameter = "Cell" Then
		ErrorText = CaptionTextOfFormElementTitle("WrongCellError", Form);
	ElsIf ScanParameter = "Products" Then
		ErrorText = CaptionTextOfFormElementTitle("ErrorWrongProduct", Form);
		If OwnGoods.ErrorType = "ProductNotFound" Then
			ErrorText = CaptionTextOfFormElementTitle("ErrorProductNotFound", Form);
		ElsIf OwnGoods.ErrorType = "PackagingIsNotLinkedToBarcode" Then
			ErrorText = CaptionTextOfFormElementTitle("ErrorIsNotLinked", Form);
		ElsIf OwnGoods.ErrorType = "UpSheetContainsPreviouslyScannedUpSheets" Then
			ErrorText = CaptionTextOfFormElementTitle("ErrorUpSheetContainsPreviouslyScannedUpSheets", Form);
		EndIf;
	ElsIf ScanParameter = "Series" Then
		ErrorText = CaptionTextOfFormElementTitle("ErrorIsWrongSeries", Form);
	ElsIf ScanParameter = "Count" Then
		If ScanValue < Form.CurrentScanningLine.NumberOfPackagingsScanned Then
			ErrorText = CaptionTextOfFormElementTitle("ErrorSmallerNumber", Form);
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
				Form.CurrentScanningLine.NumberOfPackagingsScanned);
		Else
			ErrorText = CaptionTextOfFormElementTitle("ErrorQuantityGreaterThanRequired", Form);
		EndIf;
		
		ResetSignsOfScanningAllParameters(Form);
		If ThisIsSetOfGoods 
			Or JobType = "Recalculate" Then
			
			SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
			If Not SeriesAreSpecified Then
				SetParameterScanFlag(Form, "Products", True);
			EndIf;
			
		Else
			If Not JobType = "PickingCheck" Then
				
				If JobType = "Location" Then
					
					If ThisIsProcessingOrderOfItemCell Then
						SetParameterScanFlag(Form, "Cell", True);
					Else
						SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
						
						If Not SeriesAreSpecified Then
							SetParameterScanFlag(Form, "Products", True);
						EndIf;
					EndIf;
					
				ElsIf JobType = "Move" Then
					
					If SelectionScanned
						And ThisIsProcessingOrderOfItemCell Then
						
						SetParameterScanFlag(Form, "Cell", True);
						
					Else
						SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
						If Not SeriesAreSpecified Then
							SetParameterScanFlag(Form, "Products", True);
						EndIf;
					EndIf;
					
				Else
					SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
					If Not SeriesAreSpecified Then
						SetParameterScanFlag(Form, "Products", True);
					EndIf;
				EndIf;
				
			EndIf;
		EndIf;
		
		GoToNextScanOption(Form);
		
	EndIf;
	
	Form.SeriesShelfLife = "";
	Form.BarcodeOfTheScanParameter = "";
	
	Form.EnterQuantityWeight = 0;
	Form.EnterQuantityVolume = 0;
	Form.EnterTheNumberOfTheNumber = 0;
	
	DisplayErrorMessageWhenScanningValue(Form, ErrorText);
	
EndProcedure

// Switches the top page block to the page with the error message text.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ErrorText - String - error text.
//
Procedure DisplayErrorMessageWhenScanningValue(Form, ErrorText)
	
	Form.ErrorMessage = ErrorText;
	Form.Items.PagesStateErrorText.CurrentPage = Form.Items.ErrorTextPage;
	
EndProcedure

// Switches the top page block to the page with the warning text.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	WarningText - String - warning text.
//
Procedure DisplayWarningWhenScanningValue(Form, WarningText)
	
	Form.ErrorMessage = WarningText;
	Form.Items.PagesStateErrorText.CurrentPage = Form.Items.ErrorTextPage;
	
	// Reset the warning output flag.
	Form.ModeSettings.DisplayWarningWhenScanning = False;
	Form.ModeSettings.MessageID_ = "";
	
EndProcedure

// The procedure is called after the value is scanned and performs additional checks
// and actions related to the value scan event.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure AfterScanningValue(Form)
	
	Items = Form.Items;
	CurrentScanningLine = Form.CurrentScanningLine;
	ModeSettings = Form.ModeSettings;
	JobType = Form.ModeSettings.JobType;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	SeriesAreSpecified = SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus);
	
	ResetSignsOfScanningAllParameters(Form);
	
	SetParameterScanFlag(Form, "Cell", Not ScannedCellIsSameAsCellOfScanLine(CurrentScanningLine));
	SetParameterScanFlag(Form, "Products", ScannedItemMatchesItemOfScanLine(CurrentScanningLine));
	SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
	
	If ThisIsSetOfGoods Then
		
		If JobType = "Location" Then
			SetParameterScanFlag(Form, "Cell", False);
			SetParameterScanFlag(Form, "Products", True);
		ElsIf JobType = "Receiving" Then
			SetParameterScanFlag(Form, "Cell", False);
			SetParameterScanFlag(Form, "Products", True);
			SetParameterScanFlag(Form, "Series", SeriesAreSpecified);
		ElsIf JobType = "Recalculate" Then
			GoToNextScanOption(Form);
		EndIf;
		
		If Not (Items.FormPages.CurrentPage = Items.ScanPage) Then
			GoToPage3(Form, "ScanPage");
			Form.CurrentItem = ?(JobType = "Receiving", Items.ScanTheProduct, Items.ScanCell);
		EndIf;
		
		Return;
		
	EndIf;
	
	If JobType = "Filter" Then
		
		If AllJobLinesAreScanned(Form) Then
			WhenCurJobScanIsComplete(Form);
			Return;
		EndIf;
		
		If CurJobLineScanned(Form) Then
			If ThisIsLastLineOfScan(Form) Then
				WhenCurJobScanIsComplete(Form);
				Return;
			Else
				GoToNextScanLine(Form);
			EndIf;
		EndIf;
		
	ElsIf JobType = "Location" Then
		
		If AllJobLinesAreScanned(Form) Then
			WhenCurJobScanIsComplete(Form);
			Return;
		EndIf;
		
		If ThisIsProcessingOrderOfItemCell Then
			If CurJobLineScanned(Form) Then
				SwitchToProductScanStandbyMode(Form);
			EndIf;
			GoToNextScanOption(Form);
		Else
			SetParameterScanFlag(Form, "Products", True);
			If CurJobLineScanned(Form) Then
				SetParameterScanFlag(Form, "Cell", True);
				GoToNextScanLine(Form);
			EndIf;
		EndIf;
		
	ElsIf JobType = "Move" Then
		
		If AllJobLinesAreScanned(Form) Then
			WhenCurJobScanIsComplete(Form);
			Return;
		EndIf;
		
		If SelectionScanned
			And ThisIsProcessingOrderOfItemCell Then
			
			If CurJobLineScanned(Form) Then
				SwitchToProductScanStandbyMode(Form);
			EndIf;
			GoToNextScanOption(Form);
			
		Else
			If CurJobLineScanned(Form) Then
				GoToNextScanLine(Form);
			EndIf;
		EndIf;
		
	ElsIf JobType = "Recalculate" Then
		
		If Not (Items.FormPages.CurrentPage = Items.ScanPage) Then
			GoToPage3(Form, "ScanPage");
			Form.CurrentItem = Items.ScanCell;
		EndIf;
		
	ElsIf JobType = "PickingCheck" Then
		
		If Form.ModeSettings.ScanParameter = "Count" Then
			
			ResetSignsOfScanningAllParameters(Form);
			
			If Form.SeriesScanMode = "ProductSeriesProduct" Then
				SetParameterScanFlag(Form, "Products", True);
			Else
				If SeriesAreSpecified
					And Form.TheCurrentSeriesScanParameter Then
					
					Form.TheCurrentSeriesScanParameter = False;
					SetParameterScanFlag(Form, "Series", True);
					
				Else
					SetParameterScanFlag(Form, "Products", True);
				EndIf;
			EndIf;
			
			GoToNextScanOption(Form);
			
		EndIf;
		
		If Form.ModeSettings.CachedValues = Undefined Then
			Form.ModeSettings.CachedValues = ScanLine();
		EndIf;
		
		FillPropertyValues(Form.ModeSettings.CachedValues, Form.CurrentScanningLine);
		
	Else
		
		If TaskLineScanned(CurrentScanningLine, ModeSettings) Then
			
			SetScannedQuantityOfGoods(Form);
			
			If AllJobLinesAreScanned(Form) Then
				WhenCurJobScanIsComplete(Form);
			Else
				GoToNextScanLine(Form);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets the value of the "Scan" flag to "False" for all scan parameters.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ResetSignsOfScanningAllParameters(Form)
	
	SetParameterScanFlag(Form, "Cell", False);
	SetParameterScanFlag(Form, "Products", False);
	SetParameterScanFlag(Form, "Series", False);
	SetParameterScanFlag(Form, "Count", False);
	
EndProcedure

// Sets the value of the "Scan" flag for the scan parameter
// in the scan parameters table.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ParameterName - String - name of the scan parameter.
//	Scan  - Boolean - scan mark.
//
Procedure SetParameterScanFlag(Form, ParameterName, Scan)
	
	Filter = New Structure("ParameterName", ParameterName);
	RowsArray = Form.ScanningParameters.FindRows(Filter);
	
	If RowsArray.Count() = 0 Then
		Return;
	EndIf;
	
	RowsArray[0].Scan = Scan;
	
EndProcedure

// Adds a parameter to the queue of scanning parameters
// for the warehouse employee's mobile workplace form.
//
// Parameters:
//	ScanQueue - ValueTable - queue of scan parameters,
//	ParameterName - String - name of the scan parameter,
//	Scan - Boolean - indicates whether the parameter needs to be scanned,
//	ScanningProcedure - Number - the order in which the parameter is scanned (min = 1).
//
Procedure AddParameterToScanQueue(ScanQueue, ParameterName, Scan = True, ScanningProcedure = 0)
	
	If ScanningProcedure = 0 Then
		TBLString = ScanQueue.Add();
	Else
		TBLString = ScanQueue.Insert(ScanningProcedure - 1);
	EndIf;
	
	TBLString.ParameterName = ParameterName;
	TBLString.Scan = Scan;
	
EndProcedure

// Sets the order of the scan parameter.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ParameterName - String - name of the scan parameter.
//	Order - Number - sequence number of the scan parameter.
//
Procedure SetScanParameterOrder(Form, ParameterName, Order)
	
	Filter = New Structure("ParameterName", ParameterName);
	
	RowsArray = Form.ScanningParameters.FindRows(Filter);
	
	If RowsArray.Count() = 0 Then
		Return;
	EndIf;
	
	IndexOf = Form.ScanningParameters.IndexOf(RowsArray[0]);
	
	If IndexOf = (Order - 1) Then
		Return;
	EndIf;
	
	Offset = Order - 1 - (IndexOf);
	
	Form.ScanningParameters.Move(IndexOf, Offset);
	
EndProcedure

// Returns the order in which scan parameters and scan items are crawled.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	String - the order of traversal based on the task parameters, mode parameters.
//
Function TabIndex(Form)
	
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	ProcessingProcedure_ = Form.ModeSettings.ProcessingProcedure_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	
	ThisIsPlacement = (JobType = "Location");
	ItIsTransfer = (JobType = "Move");
	
	TraversalOfElements = "StorageBinGoods";
	
	If (ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.GoodsBin)
		And ((ThisIsPlacement 
			And Not ThisIsSetOfGoods) 
		Or (ItIsTransfer 
			And SelectionScanned)) Then
		
		TraversalOfElements = "GoodsBin";
		
	EndIf;
	
	Return TraversalOfElements;
	
EndFunction

// Sets the order of scan parameters.
// 
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetOrderOfScanParameters(Form)
	
	TabIndex = TabIndex(Form);
	
	If TabIndex = "GoodsBin" Then
		
		SetScanParameterOrder(Form, "Products", 1);
		SetScanParameterOrder(Form, "Series", 2);
		SetScanParameterOrder(Form, "Count", 3);
		SetScanParameterOrder(Form, "Cell", 4);
		
	ElsIf TabIndex = "StorageBinGoods" Then
		
		SetScanParameterOrder(Form, "Cell", 1);
		SetScanParameterOrder(Form, "Products", 2);
		SetScanParameterOrder(Form, "Series", 3);
		SetScanParameterOrder(Form, "Count", 4);
		
	EndIf;
	
EndProcedure

// Sets the order of the scan items on the form according
// to the order of the scan parameters.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetOrderOfScanItems(Form)
	
	Items = Form.Items;
	
	TabIndex = TabIndex(Form);
	
	If TabIndex = "GoodsBin" Then
		
		Items.Move(Items.ScanCell, Items.ScanningParametersGroup);
		Items.Move(Items.GroupToTakeDeferred, Items.GroupQuantity);
		
	ElsIf TabIndex = "StorageBinGoods" Then
		
		Items.Move(Items.ScanTheProduct, Items.ScanningParametersGroup);
		Items.Move(Items.ScanPurpose, Items.ScanningParametersGroup);
		Items.Move(Items.ScanSeries, Items.ScanningParametersGroup);
		Items.Move(Items.GroupTaking, Items.GroupQuantity);
		
	EndIf;
	
EndProcedure

// Sets the composition of scan parameters depending on the type of task being performed 
// - set of products or scan an existing document.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CreateQueueOfScanParameters(Form)
	
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	CellsAreUsed = Not (ThisIsSetOfGoods Or (JobType = "PickingCheck" Or JobType = "Receiving"));
	SeriesProductsAreUsed = Form.UseItemsBatch;
	ScanningParameters = Form.ScanningParameters;
	ScanningParameters.Clear();
	
	Form.ModeSettings.ScanParameter = "";
	
	AddParameterToScanQueue(ScanningParameters, "Cell", CellsAreUsed);
	AddParameterToScanQueue(ScanningParameters, "Products");
	AddParameterToScanQueue(ScanningParameters, "Series", SeriesProductsAreUsed);
	AddParameterToScanQueue(ScanningParameters, "Count", False);
	
	SetOrderOfScanParameters(Form);
	SetOrderOfScanItems(Form);
	
EndProcedure

// Checks whether all packages in the scan line are scanned.
//
// Parameters:
//	JobRow - FormDataCollectionItem - the scan line.
//	ModeSettings - Structure
//	PermissibleDeviationOfSelectedGoods - Number
//
// Returns:
//	Boolean - True - the string is scanned.
//
Function TaskLineScanned(JobRow, ModeSettings, PermissibleDeviationOfSelectedGoods = 0)
	
	Scanned = False;
	JobType = ModeSettings.JobType;
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	
	If JobType = "PickingCheck" Then
		
		If DimensionalUnitsOfMeasurement.Find(JobRow.MeasuredValueType) <> Undefined Then
			MaximumQuantityOfSelectedGoods_ = JobRow.NumberOfPackages +
				JobRow.NumberOfPackages * PermissibleDeviationOfSelectedGoods / 100;
			
			Scanned = (JobRow.NumberOfPackages <= JobRow.NumberOfPackagingsScanned
					And MaximumQuantityOfSelectedGoods_ >= JobRow.NumberOfPackagingsScanned)
				Or (JobRow.NumberOfPackages = JobRow.NumberOfPackagesDoNotShip);
		Else
			Scanned = (JobRow.NumberOfPackages = JobRow.NumberOfPackagingsScanned)
				Or (JobRow.NumberOfPackages = JobRow.NumberOfPackagesDoNotShip);
		EndIf;
		
	ElsIf JobType = "Filter"
		And DimensionalUnitsOfMeasurement.Find(JobRow.MeasuredValueType) <> Undefined Then
		
		MaximumQuantityOfSelectedGoods_ = JobRow.NumberOfPackages +
			JobRow.NumberOfPackages * PermissibleDeviationOfSelectedGoods / 100;
		
		Scanned = JobRow.NumberOfPackages <= JobRow.NumberOfPackagingsScanned
			And MaximumQuantityOfSelectedGoods_ >= JobRow.NumberOfPackagingsScanned
		
	Else
		Scanned = (JobRow.NumberOfPackages = JobRow.NumberOfPackagingsScanned);
	EndIf;
	
	Return Scanned;
	
EndFunction

// Checks whether the current line of the warehouse task has been fully processed (scanned).
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - True - the current line of the warehouse task is fully worked out.
//
Function CurJobLineScanned(Form)
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100;
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	
	If Not ScannedItemMatchesItemOfScanLine(CurrentScanningLine) Then
		Return False;
	EndIf;
	
	If Not ScannedCellIsSameAsCellOfScanLine(CurrentScanningLine) Then
		Return False;
	EndIf;
	
	If JobType = "Filter"
		And DimensionalUnitsOfMeasurement.Find(CurrentScanningLine.MeasuredValueType) <> Undefined Then
		
		MaximumQuantityOfSelectedGoods_ = CurrentScanningLine.NumberOfPackages +
			CurrentScanningLine.NumberOfPackages * PermissibleDeviationOfSelectedGoods;
		
		If Not (CurrentScanningLine.NumberOfPackages <= CurrentScanningLine.NumberOfPackagingsScanned
			And MaximumQuantityOfSelectedGoods_ >= CurrentScanningLine.NumberOfPackagingsScanned) Then
			
			Return False;
			
		EndIf;
		
	Else
		If Not (CurrentScanningLine.NumberOfPackages = CurrentScanningLine.NumberOfPackagingsScanned) Then
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Checks the fact of a full scan of all the lines of the warehouse task's product lines.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - Flag for scanning all lines of the task.
//
Function AllJobLinesAreScanned(Form)
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	GoodsForScanning = Form.GoodsForScanning;
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100;
	
	If (JobType = "Filter"
			Or JobType = "PickingCheck")
		And PermissibleDeviationOfSelectedGoods > 0 Then
		
		DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
		MaximumQuantityOfSelectedGoods_ = 0;
		
		For Each RowOfProduct In GoodsForScanning Do
			If DimensionalUnitsOfMeasurement.Find(RowOfProduct.MeasuredValueType) = Undefined Then
				MaximumQuantityOfSelectedGoods_ = MaximumQuantityOfSelectedGoods_ + RowOfProduct.NumberOfPackages;
			Else
				MaximumQuantityOfSelectedGoods_ = MaximumQuantityOfSelectedGoods_ +
					RowOfProduct.NumberOfPackages + RowOfProduct.NumberOfPackages * PermissibleDeviationOfSelectedGoods;
			EndIf;
		EndDo;
		
		Return GoodsForScanning.Total("NumberOfPackages") <= GoodsForScanning.Total("NumberOfPackagingsScanned")
			And MaximumQuantityOfSelectedGoods_ >= GoodsForScanning.Total("NumberOfPackagingsScanned")
		
	Else
		Return GoodsForScanning.Total("NumberOfPackages") = GoodsForScanning.Total("NumberOfPackagingsScanned");
	EndIf;
	
EndFunction

// Checks whether the item is a product.
//
// Parameters:
//	StructureOfData - FormDataCollectionItem, Structure - any data structure to check.
//
// Returns:
//	Boolean - True - the nomenclature is a commodity, False - not.
//
Function ThisIsAProduct(StructureOfData)
	
	Return (StructureOfData.ItemsType = Enums.ItemsTypes.OwnGoods);
	
EndFunction

// Checks whether the item is a container.
//
// Parameters:
//	StructureOfData - FormDataCollectionItem, Structure - any data structure to check.
//
// Returns:
//	Boolean - True - the nomenclature is a container, False - not.
//
Function ThisIsTara(StructureOfData)
	
	Return (StructureOfData.ItemsType = Enums.ItemsTypes.ReusablePackage);
	
EndFunction

Function ThisIsAPackingList(StructureOfData)
	
	Return ValueIsFilled(StructureOfData.PackingList);
	
EndFunction

Function ThisIsUnknownBarcode(StructureOfData)
	
	Return Not ValueIsFilled(StructureOfData.PackingList)
		And Not ValueIsFilled(StructureOfData.Products)
		And ValueIsFilled(StructureOfData.Barcode);
	
EndFunction

Function WHBarcodes(Form)
	
	Return Form.UsePackingLists
		And Form.ModeSettings.JobType = "Receiving";
	
EndFunction

// Adds information to the product structure - description, name, article.
// Is used in the formation of the title text of the elements of the scan.
//
// Parameters:
//	ProductParameters_1 - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
// Returns:
//	Structure - See OwnGoods
//
Function FindProductByParameters(ProductParameters_1)
	
	OwnGoods = OwnGoods();
	
	OwnGoods.ReturnCode = 1;
	OwnGoods.SKU = ProductParameters_1.ProductIDOfItems;
	OwnGoods.LongDesc = ProductParameters_1.ItemsDescription;
	OwnGoods.Description = ProductParameters_1.ItemName;
	
	FillPropertyValues(OwnGoods, ProductParameters_1);
	
	Return OwnGoods;
	
EndFunction

// Returns a structure for storing product information.
// 
// Returns:
//	Structure - description of the item, contains the following fields:
//	* PackingList - DocumentRef.PackingList - packing list that includes the product.
//	* ThisIsAPackingList - Boolean - True if the product is used as a packing list.
//	* MeasuredValueType - EnumRef.TypesOfMeasuredValues - type measured veocine product.
//	* UnitOfMeasureForVolume - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement for the product volume.
//	* UnitOfMeasureForWeight - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement for the product weight.
//	* UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement of the product.
//	* PackageVolume - Number - value of the product packaging volume.
//	* PackageWeight - Number - value of the product package weight.
//	* FactorOfVolumeUnitOfMeasure - Number - the ratio of the volume of product packaging.
//	* FactorOfWeightUnitOfMeasure - Number - the weight ratio of the product packaging.
//	* ZoomRatio - Number - product packaging coefficient.
//	* Package - CatalogRef.PackagesAndUnitsOfMeasure - packing.
//	* Purpose - CatalogRef.Assignments - information about the product separation.
//	* PrecisionOfBatchShelfLifeIndication - EnumRef.AccuracyOfShelfLifeIndication - accuracy of the period of use of the product series.
//	* UseShelfLifeOnBatchRegistration - Boolean - True if information about the expiration date of the product series is used.
//	* SpecifyNumberWhenRegisteringBatch - Boolean - True if series accounting is used in the context of numbers.
//	* ValidUntil_ - Date - expiration date of the product series.
//	* BatchNumber - String - serial number.
//	* Series - CatalogRef.ItemsBatches - product series.
//	* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//	* ItemsType - EnumRef.ItemsTypes - type of goods.
//	* ProductKind - CatalogRef.ItemKinds - type of goods.
//	* QuantityByBarcode - Number - the quantity of the product that is contained in its barcode information.
//	* Barcode - String - the barcode of the product.
//	* LongDesc - String - information about the product.
//	* SKU - String - item number.
//	* Description - String - the name of the product.
//	* Products - CatalogRef.Products - product.
//	* MessageText - String - message to the user about errors detected when scanning the product barcode.
//	* ErrorType - String - error type scan the barcode of the product.
//	* ReturnCode - Number - the result of scanning the product's barcode.
//
Function OwnGoods() Export
	
	OwnGoods = New Structure;
	
	OwnGoods.Insert("ReturnCode", 1);
	OwnGoods.Insert("ErrorType", "");
	OwnGoods.Insert("MessageText", "");
	
	OwnGoods.Insert("Products", Catalogs.Products.EmptyRef());
	OwnGoods.Insert("Description", "");
	OwnGoods.Insert("SKU", "");
	OwnGoods.Insert("LongDesc", "");
	OwnGoods.Insert("Barcode", ""); // To save barcodes during acceptance
	OwnGoods.Insert("QuantityByBarcode", 0);
	
	OwnGoods.Insert("ProductKind", Catalogs.ItemKinds.EmptyRef());
	OwnGoods.Insert("ItemsType", Enums.ItemsTypes.EmptyRef());
	
	OwnGoods.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	
	OwnGoods.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	OwnGoods.Insert("BatchNumber", "");
	OwnGoods.Insert("ValidUntil_", Date("00010101"));
	
	OwnGoods.Insert("SpecifyNumberWhenRegisteringBatch", False);
	OwnGoods.Insert("UseShelfLifeOnBatchRegistration", False);
	OwnGoods.Insert("PrecisionOfBatchShelfLifeIndication", Enums.AccuracyOfShelfLifeIndication.EmptyRef());
	
	OwnGoods.Insert("Purpose", Catalogs.Assignments.EmptyRef());
	
	OwnGoods.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	OwnGoods.Insert("ZoomRatio", 0);
	OwnGoods.Insert("FactorOfWeightUnitOfMeasure", 0);
	OwnGoods.Insert("FactorOfVolumeUnitOfMeasure", 0);
	
	OwnGoods.Insert("PackageWeight", 0);
	OwnGoods.Insert("PackageVolume", 0);
	
	OwnGoods.Insert("UnitOfMeasure", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	OwnGoods.Insert("UnitOfMeasureForWeight", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	OwnGoods.Insert("UnitOfMeasureForVolume", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	OwnGoods.Insert("MeasuredValueType", Enums.TypesOfMeasuredValues.EmptyRef());
	
	OwnGoods.Insert("ThisIsAPackingList", False);
	OwnGoods.Insert("PackingList", Documents.PackingList.EmptyRef());
	
	Return OwnGoods;
	
EndFunction

// Returns a description of the warehouse job scan line.
// 
// Returns:
// 	Structure - LongDesc:
// * QuantityOfGoodsInABin - Number - the number of products in the cell.
// * GoodsNumberInTheBin - Number - the serial number of the item in the cell.
// * NumberOfBins - Number - number of cells.
// * CellNumber - Number - sequence number of the cell.
// * ThereAreGoodsUnshipped - Boolean - True if there are unloaded items found during the warehouse
// 									task.
// * ThereIsShortage - Boolean - The truth is, if there is a shortage of goods in the selection of goods from the warehouse of the cell.
// * OriginalLineNumber - Number - the sequential number of the product line in accordance with the warehouse task.
// * LineNumber - Number - serial number of the product line.
// * ActiveString - Number - the warehouse task line to process.
// * QuantityOfGoodsInDocument - Number - the number of items in accordance with the warehouse task.
// * DoNotShip - Number - the number of unloaded items.
// * QuantityNotToShip - Number - the number of unloaded items.
// * NumberOfPackagesPut - Number - the number of items placed in the storage cell.
// * NumberOfPackagesToPut - Number - the number of products that must be disposed of in accordance with the inventory job.
// * NumberOfPackagesInDocument - Number - the number of product packages in the document.
// * NumberOfPackagesDoNotShip - Number - number of packages of unloaded goods.
// * NumberOfPackagingsScanned - Number - the number of scanned product packages.
// * NumberOfPackages - Number - number of product packages.
// * ScPackingListParent - DocumentRef.PackingList - scanned parent packing list.
// * SKIsPackingList - Boolean - True, the scanned product line is a packing list.
// * ScPackingList - DocumentRef.PackingList - scanned packing list.
// * SkPackaging - CatalogRef.PackagesAndUnitsOfMeasure - scanned the product packaging.
// * SKIsGoodTo - Date - scanned shelf life of the product series.
// * SKSeriesNumber - String - the scanned batch number of the product.
// * SkSeries - CatalogRef.ItemsBatches - scanned a series of goods.
// * SCCharacteristics - CatalogRef.ItemsCharacteristics - the scanned characteristics of the goods.
// * SKProducts - CatalogRef.Products - the item being scanned.
// * SKCellCode - String - the cell code to scan.
// * SKCell - CatalogRef.StorageBins - the cell to scan.
// * QuantityByBarcode - Number -the quantity of the product according to the barcode.
// * Barcode - String - barcode teaware.
// * PackingListParent - DocumentRef.PackingList - parent packing list.
// * ThisIsAPackingList - Boolean - True, the product line is a packing list.
// * PackingList - DocumentRef.PackingList - packing list.
// * PrecisionOfBatchShelfLifeIndication - EnumRef.AccuracyOfShelfLifeIndication - accuracy of indicating
// 																								the expiration date of the product series.
// * UseShelfLifeOnBatchRegistration - Boolean - The truth is, if you are using profitability of lots of goods on the shelf life.
// * SpecifyNumberWhenRegisteringBatch - Boolean - The truth is, if you are using a serial account of the goods.
// * BatchesIndicationStatus - Number - the status of the series indication.
// * MeasuredValueType - EnumRef.TypesOfMeasuredValues - type of the measured value of the product.
// * NameOfVolumeUnitOfMeasure - String - name of the unit of measurement for the product volume.
// * UnitOfMeasureForVolume - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement for the product volume.
// * NameOfWeightUnitOfMeasure - String - name of the item's weight measurement unit.
// * UnitOfMeasureForWeight - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement for the product weight.
// * UnitOfMeasureDescription - String - name of the item's unit of measurement.
// * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement of the product.
// * PackageVolume - Number - the volume of product packaging.
// * PackageWeight - Number - weight of the product package.
// * FactorOfVolumeUnitOfMeasure - Number - coefficient of the unit of measurement of the package volume.
// * FactorOfWeightUnitOfMeasure - Number - coefficient of the unit of measurement for the package weight.
// * ZoomRatio - Number - product packaging coefficient.
// * PackageName - String - name of the package.
// * Package - CatalogRef.PackagesAndUnitsOfMeasure - packing.
// * NewAssignment - CatalogRef.Assignments - new purpose of product storage isolation.
// * PurposeDescription - String - name of the purpose of separate storage of the product.
// * Purpose - CatalogRef.Assignments - purpose of separation of storage of goods.
// * BatchNumber - String - the batch number of the product.
// * ValidUntil_ - Date - expiration date of the product series.
// * BatchName - String - name of the product series.
// * Series - CatalogRef.ItemsBatches - product series.
// * ItemVariantName - String - name of the product specification.
// * Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
// * ItemsBarcode - String - the barcode of the product.
// * ItemsType - EnumRef.ItemsTypes - type of goods.
// * ProductKind - CatalogRef.ItemKinds - type of goods.
// * ItemsDescription - String - product description.
// * ProductIDOfItems - String - item number.
// * ItemName - String - the name of the product.
// * Products - CatalogRef.Products - product.
// * CellBarcode - String - barcode of the storage cell.
// * CellCode - String - code of the storage cell.
// * Cell - CatalogRef.StorageBins - storage cell.
//
Function ScanLine()
	
	StringStructure = New Structure;
	
	StringStructure.Insert("Cell", Catalogs.StorageBins.EmptyRef());
	StringStructure.Insert("CellCode", "");
	StringStructure.Insert("CellBarcode", "");
	
	StringStructure.Insert("Products", Catalogs.Products.EmptyRef());
	StringStructure.Insert("ItemName", "");
	StringStructure.Insert("ProductIDOfItems", "");
	StringStructure.Insert("ItemsDescription", "");
	
	StringStructure.Insert("ProductKind", Catalogs.ItemKinds.EmptyRef());
	StringStructure.Insert("ItemsType", Enums.ItemsTypes.EmptyRef());
	StringStructure.Insert("ItemsBarcode", "");
	
	StringStructure.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	StringStructure.Insert("ItemVariantName", "");
	
	StringStructure.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	StringStructure.Insert("BatchName", "");
	StringStructure.Insert("ValidUntil_", Date("00010101"));
	StringStructure.Insert("BatchNumber", "");
	
	StringStructure.Insert("Purpose", Catalogs.Assignments.EmptyRef());
	StringStructure.Insert("PurposeDescription", "");
	StringStructure.Insert("NewAssignment", Catalogs.Assignments.EmptyRef());
	
	StringStructure.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	StringStructure.Insert("PackageName", "");
	
	StringStructure.Insert("ZoomRatio", 0);
	StringStructure.Insert("FactorOfWeightUnitOfMeasure", 0);
	StringStructure.Insert("FactorOfVolumeUnitOfMeasure", 0);
	
	StringStructure.Insert("PackageWeight", 0);
	StringStructure.Insert("PackageVolume", 0);
	
	StringStructure.Insert("UnitOfMeasure", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	StringStructure.Insert("UnitOfMeasureDescription", "");
	
	StringStructure.Insert("UnitOfMeasureForWeight", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	StringStructure.Insert("NameOfWeightUnitOfMeasure", "");
	
	StringStructure.Insert("UnitOfMeasureForVolume", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	StringStructure.Insert("NameOfVolumeUnitOfMeasure", "");
	
	StringStructure.Insert("MeasuredValueType", Enums.TypesOfMeasuredValues.EmptyRef());
	
	StringStructure.Insert("BatchesIndicationStatus", 0);
	StringStructure.Insert("SpecifyNumberWhenRegisteringBatch", False);
	StringStructure.Insert("UseShelfLifeOnBatchRegistration", False);
	
	StringStructure.Insert("PrecisionOfBatchShelfLifeIndication", 
		Enums.AccuracyOfShelfLifeIndication.EmptyRef());
	
	StringStructure.Insert("PackingList", Documents.PackingList.EmptyRef());
	StringStructure.Insert("ThisIsAPackingList", False);
	StringStructure.Insert("PackingListParent", Documents.PackingList.EmptyRef());
	
	StringStructure.Insert("Barcode", "");
	StringStructure.Insert("QuantityByBarcode", 0);
	
	StringStructure.Insert("SKCell", Catalogs.StorageBins.EmptyRef());
	StringStructure.Insert("SKCellCode", "");
	StringStructure.Insert("SKProducts", Catalogs.Products.EmptyRef());
	StringStructure.Insert("SCCharacteristics", Catalogs.ItemsCharacteristics.EmptyRef());
	
	StringStructure.Insert("SkSeries", Catalogs.ItemsBatches.EmptyRef());
	StringStructure.Insert("SKSeriesNumber", "");
	StringStructure.Insert("SKIsGoodTo", Date("00010101"));
	
	StringStructure.Insert("SkPackaging", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	StringStructure.Insert("ScPackingList", Documents.PackingList.EmptyRef());
	StringStructure.Insert("SKIsPackingList", False);
	StringStructure.Insert("ScPackingListParent", Documents.PackingList.EmptyRef());
	
	StringStructure.Insert("NumberOfPackages", 0);
	StringStructure.Insert("NumberOfPackagingsScanned", 0);
	StringStructure.Insert("NumberOfPackagesDoNotShip", 0);
	StringStructure.Insert("NumberOfPackagesInDocument", 0);
	
	StringStructure.Insert("NumberOfPackagesToPut", 0);
	StringStructure.Insert("NumberOfPackagesPut", 0);
	
	StringStructure.Insert("QuantityNotToShip", 0);
	StringStructure.Insert("DoNotShip", 0);
	StringStructure.Insert("QuantityOfGoodsInDocument", 0);
	
	StringStructure.Insert("ActiveString", 0);
	
	StringStructure.Insert("LineNumber", 0);
	StringStructure.Insert("OriginalLineNumber", 0);
	
	StringStructure.Insert("ThereIsShortage", False);
	StringStructure.Insert("ThereAreGoodsUnshipped", False);
	
	StringStructure.Insert("CellNumber", 0);
	StringStructure.Insert("NumberOfBins", 0);
	
	StringStructure.Insert("GoodsNumberInTheBin", 0);
	StringStructure.Insert("QuantityOfGoodsInABin", 0);
	
	Return StringStructure;
	
EndFunction

// Returns the structure of mode parameters. The structure contains the necessary auxiliary
// values for the functioning of the warehouse worker's workplace.
//
// Returns:
//	Structure - mode parameters.
//
Function ModeSettings()
	
	ModeSettings = New Structure;
	
	ModeSettings.Insert("Mode", "");
	ModeSettings.Insert("ClosingForm_", False);
	
	ModeSettings.Insert("SetOfProducts_", False);
	ModeSettings.Insert("Job", Undefined);
	
	ModeSettings.Insert("NameOfTheWarehouse", "");
	ModeSettings.Insert("WareroomName", "");
	
	ModeSettings.Insert("ReceivingArea", Undefined);
	ModeSettings.Insert("NameOfAcceptanceZone", "");
	ModeSettings.Insert("DefaultAcceptanceZone", Undefined);
	
	ModeSettings.Insert("ShippingZone", Undefined);
	ModeSettings.Insert("NameOfShippingArea", "");
	
	ModeSettings.Insert("SelectionOfShipmentAcceptanceZone", "");
	
	ModeSettings.Insert("JobType", Undefined);
	ModeSettings.Insert("SelectionScanned", False);
	ModeSettings.Insert("PlacementScanned", False);
	ModeSettings.Insert("GoodsAreDistributed", True);
	ModeSettings.Insert("ScanParameter", "");
	ModeSettings.Insert("YouCanCloseForm", False);
	
	ModeSettings.Insert("NumberOfSelectionLines", 0);
	ModeSettings.Insert("NumberOfPlacementLines", 0);
	ModeSettings.Insert("NumberOfRecalculationLines", 0);
	
	ModeSettings.Insert("NumberOfSelectionCells_", 0);
	ModeSettings.Insert("NumberOfPlacementCells", 0);
	ModeSettings.Insert("NumberOfRecalculationCells", 0);
	
	ModeSettings.Insert("NumberOfSelectionPackages", 0);
	ModeSettings.Insert("NumberOfPlacementPackages", 0);
	ModeSettings.Insert("NumberOfPackagesRecalculated", 0);
	
	ModeSettings.Insert("CreatedJob", Undefined);
	
	ModeSettings.Insert("ProcessingProcedure_", Undefined);
	ModeSettings.Insert("SourceExecutor", "");
	
	// Designed to display a warning when scanning without setting the error flag.
	// It is required in the case, for example, of a selection check, when a product is scanned that
	// is not in the expenditure order being checked.
	ModeSettings.Insert("DisplayWarningWhenScanning", False);
	ModeSettings.Insert("MessageID_", "");
	ModeSettings.Insert("CachedValues");
	
	Return ModeSettings;
	
EndFunction

// Adds information about the scanned product to the scanned product table.
// Called after the value is scanned.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ThisIsInputAsIntended - Boolean
//
Procedure AddToScannedProducts(Form, ThisIsInputAsIntended = False)
	
	ScannedGoods = Form.ScannedGoods;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	
	CurrentScanningLine = Form.CurrentScanningLine;
	ThisIsAPackingList = ThisIsAPackingList(CurrentScanningLine);
	ThisIsUnknownBarcode = ThisIsUnknownBarcode(CurrentScanningLine);
	
	If ThisIsAPackingList Then 
		Filter = New Structure("PackingList");
	ElsIf ThisIsUnknownBarcode Then
		Filter = New Structure("Barcode");
	Else
		
		If (JobType = "Filter"
				Or JobType = "Move")
			And SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) Then
			
			Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber, ValidUntil_");
			
		Else
			Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
		EndIf;
		
	EndIf;
	
	FillPropertyValues(Filter, CurrentScanningLine);
	
	RowsArray = ScannedGoods.FindRows(Filter);
	
	If Not RowsArray.Count() > 0 Then
		
		NewRow = ScannedGoods.Add();
		FillPropertyValues(NewRow, CurrentScanningLine);
		
		If Not ThisIsAPackingList
			And ValueIsFilled(CurrentScanningLine.Package) Then
			
			FillInParametersOfScannedProduct(Form, NewRow, True);
			
		EndIf;
		
		If NewRow.ZoomRatio <> 0 Then
			NewRow.Count = NewRow.NumberOfPackagingsScanned * NewRow.ZoomRatio;
		Else
			NewRow.Count = NewRow.NumberOfPackagingsScanned;
		EndIf;
		
	Else
		If ThisIsAPackingList Then
			Form.ModeSettings.DisplayWarningWhenScanning = True;
			Form.ModeSettings.MessageID_ = "WarningPackingListHasAlreadyBeenScanned";
			CurrentScanningLine.NumberOfPackagingsScanned = 1;
		Else
			TBLString = RowsArray[0];
			
			If Not ((ModeSettings.Mode = "EnterQuantity")
				Or (ModeSettings.Mode = "EnteringQuantityAsIntended")) Then
				
				CurrentScanningLine.NumberOfPackagingsScanned = TBLString.NumberOfPackagingsScanned + 1;
				
			EndIf;
			
			If ThisIsInputAsIntended
				And (CurrentScanningLine.NewAssignment = CurrentScanningLine.Purpose) Then
				
				TBLString.NumberOfPackagingsScanned = TBLString.NumberOfPackagingsScanned
					+ CurrentScanningLine.NumberOfPackagingsScanned;
				TBLString.NumberOfPackagesDoNotShip = AdjustedNumberOfPackagesDoNotShip(TBLString,
					PermissibleDeviationOfSelectedGoods);
				
			Else
				TBLString.NumberOfPackagingsScanned = CurrentScanningLine.NumberOfPackagingsScanned;
				TBLString.NumberOfPackagesDoNotShip = AdjustedNumberOfPackagesDoNotShip(CurrentScanningLine,
					PermissibleDeviationOfSelectedGoods);
			EndIf;
			
			FillInParametersOfScannedProduct(Form, TBLString);
			
			If (JobType = "PickingCheck")
				And SeriesAreSpecifiedForReference(TBLString.BatchesIndicationStatus) Then
				
				FillPropertyValues(CurrentScanningLine, TBLString, , "NumberOfPackages,
					|NumberOfPackagesInDocument");
				
			Else
				FillPropertyValues(CurrentScanningLine, TBLString);
			EndIf;
			
			If TBLString.ZoomRatio <> 0 Then
				TBLString.Count = TBLString.NumberOfPackagingsScanned * TBLString.ZoomRatio;
			Else
				TBLString.Count = TBLString.NumberOfPackagingsScanned;
			EndIf;
		EndIf;
	EndIf;
	
	SetParametersOfScannedProducts(Form);
	SetScannedQuantityOfGoods(Form, False);
	AddContainerForScannedProduct(Form);
	SetQuantityForAccountingInGoodsForRecalculation(Form);
	
EndProcedure

// Adds information about the scanned container to the scanned container table.
// Called after the value is scanned.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure AddContainersToScannedContainers(Form)
	
	If Not Form.UseReusablePackage Then
		Return;
	EndIf;
	
	// Get a table of the packaging of the scanned product.
	PackageTable = ReusablePackageServer.ReusablePackagingOfProductRange(Form.CurrentScanningLine.Products,
		Form.CurrentScanningLine.Package);
	
	If PackageTable.Count() = 0 Then
		Return;
	EndIf;
	
	ProductColumns = "GoodsBin, RangeOfGoods, ProductItemCharacteristic, ItemProductSeries, GoodsPackaging";
	ContainerColumns = "Products, Characteristic";
	
	Filter = New Structure;
	
	Filter.Insert("GoodsBin", Form.CurrentScanningLine.SKCell);
	Filter.Insert("RangeOfGoods", Form.CurrentScanningLine.SKProducts);
	Filter.Insert("ProductItemCharacteristic", Form.CurrentScanningLine.SCCharacteristics);
	Filter.Insert("ItemProductSeries", Form.CurrentScanningLine.SkSeries);
	Filter.Insert("GoodsPackaging", Form.CurrentScanningLine.SkPackaging);
	Filter.Insert("Purpose", Form.CurrentScanningLine.Purpose);
	
	DZScannedContainer = Form.FormAttributeToValue("ScannedPackage");
	
	// Find the product line in the tree.
	RowsArray = DZScannedContainer.Rows.FindRows(Filter);
	If RowsArray.Count() = 0 Then
		RowOfProduct = DZScannedContainer.Rows.Add();
		FillPropertyValues(RowOfProduct, Filter);
	Else
		RowOfProduct = RowsArray[0];
	EndIf;
	
	// Add rows from the container table to the rows of the scanned container tree.
	SelectionByContainer = New Structure("Products, Characteristic");
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	
	For Each TBLString In PackageTable Do
		
		FillPropertyValues(SelectionByContainer, TBLString);
		
		ArrayOfContainerStrings = RowOfProduct.Rows.FindRows(SelectionByContainer);
		
		If ArrayOfContainerStrings.Count() = 0 Then
			TareString = RowOfProduct.Rows.Add();
			
			FillPropertyValues(TareString, RowOfProduct, ProductColumns);
			FillPropertyValues(TareString, TBLString, ContainerColumns);
			
			TareString.ZoomRatio = 1;
			TareString.NumberOfPackagingsScanned = Form.CurrentScanningLine.NumberOfPackagingsScanned *
				TBLString.Count;
			TareString.NumberOfPackagesDoNotShip =
				AdjustedNumberOfPackagesDoNotShip(Form.CurrentScanningLine,
					PermissibleDeviationOfSelectedGoods) * TBLString.Count;
		Else
			TareString = ArrayOfContainerStrings[0];
			TareString.NumberOfPackagingsScanned = Form.CurrentScanningLine.NumberOfPackagingsScanned *
				TBLString.Count;
			TareString.NumberOfPackagesDoNotShip = 
				AdjustedNumberOfPackagesDoNotShip(Form.CurrentScanningLine,
					PermissibleDeviationOfSelectedGoods) * TBLString.Count;
		EndIf;
		
	EndDo;
	
	Form.ValueToFormAttribute(DZScannedContainer, "ScannedPackage");
	
EndProcedure

// Adds information about the container for the scanned product to the scanned product table.
// Called after the value is scanned.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure AddSetContainerToProductsForScanning(Form)
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	
	// Get a table of the packaging of the scanned product.
	PackageTable = ReusablePackageServer.ReusablePackagingOfProductRange(Form.CurrentScanningLine.Products,
		Form.CurrentScanningLine.Package);
	
	VTProductsForScanning = Form.FormAttributeToValue("GoodsForScanning");
	VTBalancesOfGoodsInCell = Form.Object.StockOfGoodsInBin.Unload();
	
	Filter = New Structure("Cell, Products, Characteristic");
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	
	For Each TareTableRow In PackageTable Do
		
		FillPropertyValues(Filter, TareTableRow);
		
		Filter.Cell = Form.CurrentScanningLine.Cell;
		
		RowsArray = VTProductsForScanning.FindRows(Filter);
		ArrayOfTareRowsLeftovers = VTBalancesOfGoodsInCell.FindRows(Filter);
		
		If RowsArray.Count() = 0 Then
			
			// There is no such container in the queue for scanning in this cell, you need to add
			// the container to the table for additional scanning. After the scanning of this product is completed,
			// it is necessary to offer the employee to scan the container. Those lines that will not be scanned will
			// remain in the task as unfulfilled. The task will have the status "Completed with errors".
			// A new line of packaging must be inserted after the current line
			// so that you can scan the packaging of this product immediately after the product is scanned.
			
			If ModeSettings.JobType = "PickingCheck" Then
				Continue;
			EndIf;
			
			ProductLineToScan = VTProductsForScanning.Find(1, "ActiveString");
			
			If ProductLineToScan <> Undefined Then
				
				NewContainerLine = VTProductsForScanning.Insert(VTProductsForScanning.IndexOf(ProductLineToScan) + 1);
				
				FillPropertyValues(NewContainerLine, TareTableRow);
				
				NewContainerLine.Cell = Form.CurrentScanningLine.Cell;
				NewContainerLine.ZoomRatio = 1;
				
				NewContainerLine.NumberOfPackagingsScanned = Form.CurrentScanningLine.NumberOfPackagingsScanned
					* TareTableRow.Count;
				
				If (ModeSettings.JobType = "Recalculate"
					Or ModeSettings.JobType = "Receiving") Then
					
				ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
					If (JobType = "Filter"
							Or JobType = "Move")
						And SeriesAreIndicatedUponSelection(Form.CurrentScanningLine.BatchesIndicationStatus) Then
						
						FilterOfProducts_ = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber,
							|ValidUntil_");
						
					Else
						FilterOfProducts_ = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
					EndIf;
					
					FillPropertyValues(FilterOfProducts_, Form.CurrentScanningLine);
					
					ArrayOfRowsProductBalances = VTBalancesOfGoodsInCell.FindRows(FilterOfProducts_);
					
					If ArrayOfRowsProductBalances.Count() = 0 Then
						ProductLineIndex = 0;
					Else
						ProductLineIndex = VTBalancesOfGoodsInCell.IndexOf(ArrayOfRowsProductBalances[0]);
					EndIf;
					
					If ArrayOfTareRowsLeftovers.Count() = 0 Then
						NewRowOfBalances = VTBalancesOfGoodsInCell.Insert(ProductLineIndex + 1);
						
						FillPropertyValues(NewRowOfBalances, TareTableRow);
						
						SetUnitOfMeasurementOfTareGoodsResiduesOfGoodsInCell(NewRowOfBalances);
						NewRowOfBalances.BatchPresentation = SetSeriesPresentation(Form.CurrentScanningLine);
						
						NewRowOfBalances.Cell = FilterOfProducts_.Cell;
						NewRowOfBalances.QuantityScanned = Form.CurrentScanningLine.NumberOfPackagingsScanned
							* TareTableRow.Count;
					Else
						ArrayOfTareRowsLeftovers[0].QuantityScanned = ArrayOfTareRowsLeftovers[0].Count
							+ Form.CurrentScanningLine.NumberOfPackagingsScanned * TareTableRow.Count;
							
						TareRowIndex = VTBalancesOfGoodsInCell.IndexOf(ArrayOfTareRowsLeftovers[0]);
						NumberOfOffsetRows = TareRowIndex - ProductLineIndex - 1;
						VTBalancesOfGoodsInCell.Move(ArrayOfTareRowsLeftovers[0], -NumberOfOffsetRows);
					EndIf;
				EndIf;
				
			EndIf;
			
		Else
			
			// There may be rows with already scanned containers in the packaging table
			// , it is necessary to distribute the scanned quantity of goods to rows with 
			// un-scanned containers.
			
			If ModeSettings.JobType = "PickingCheck"
				And SeriesAreSpecifiedForReference(RowsArray[0].BatchesIndicationStatus) Then
				
				Continue;
				
			EndIf;
			
			IndexOf = 0;
			QuantityForDistribution = Form.CurrentScanningLine.NumberOfPackagingsScanned * TareTableRow.Count;
			
			While QuantityForDistribution > 0 And Not (IndexOf > RowsArray.UBound()) Do
				
				TareString = RowsArray[IndexOf];
				
				If TareString.NumberOfPackagingsScanned < TareString.NumberOfPackagesInDocument Then
					
					TareString.ZoomRatio = 1;
					TareString.NumberOfPackagingsScanned = TareString.NumberOfPackagingsScanned + 
							Min(TareString.NumberOfPackagesInDocument, QuantityForDistribution);
					
					If Not TareString.DoNotShip = 1 Then
						TareString.NumberOfPackagesDoNotShip =
							AdjustedNumberOfPackagesDoNotShip(Form.CurrentScanningLine, PermissibleDeviationOfSelectedGoods) *
								TareTableRow.Count;
					EndIf;
					
					QuantityForDistribution = QuantityForDistribution - TareString.NumberOfPackagingsScanned;
					
					If (ModeSettings.JobType = "Recalculate" 
						Or ModeSettings.JobType = "PickingCheck"
						Or ModeSettings.JobType = "Receiving") Then
						// For warehouse tasks "Recalculation", "Acceptance" and "Selection Check", there is no output of information about goods
						// processed in accordance with the task when processing with a resolution of "480x640".
					ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
						
						If (JobType = "Filter"
								Or JobType = "Move")
							And SeriesAreIndicatedUponSelection(Form.CurrentScanningLine.BatchesIndicationStatus) Then
							
							FilterOfProducts_ = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber,
								|ValidUntil_");
							
						Else
							FilterOfProducts_ = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
						EndIf;
						
						FillPropertyValues(FilterOfProducts_, Form.CurrentScanningLine);
						
						ArrayOfRowsProductBalances = VTBalancesOfGoodsInCell.FindRows(FilterOfProducts_);
						
						If ArrayOfRowsProductBalances.Count() = 0 Then
							ProductLineIndex = 0;
						Else
							ProductLineIndex = VTBalancesOfGoodsInCell.IndexOf(ArrayOfRowsProductBalances[0]);
						EndIf;
						
						If ArrayOfTareRowsLeftovers.Count() = 0 Then
							NewRowOfBalances = VTBalancesOfGoodsInCell.Insert(ProductLineIndex + 1);
							
							FillPropertyValues(NewRowOfBalances, TareTableRow);
							
							SetUnitOfMeasurementOfTareGoodsResiduesOfGoodsInCell(NewRowOfBalances);
							NewRowOfBalances.BatchPresentation = SetSeriesPresentation(Form.CurrentScanningLine);
							
							NewRowOfBalances.Cell = FilterOfProducts_.Cell;
							NewRowOfBalances.QuantityScanned = TareString.NumberOfPackagingsScanned;
						Else
							ArrayOfTareRowsLeftovers[0].QuantityScanned = 
								ArrayOfTareRowsLeftovers[0].Count + TareString.NumberOfPackagingsScanned;
								
							TareRowIndex = VTBalancesOfGoodsInCell.IndexOf(ArrayOfTareRowsLeftovers[0]);
							NumberOfOffsetRows = TareRowIndex - ProductLineIndex - 1;
							VTBalancesOfGoodsInCell.Move(ArrayOfTareRowsLeftovers[0], -NumberOfOffsetRows);
						EndIf;
						
					EndIf;
					
				EndIf;
				
				IndexOf = IndexOf + 1;
				
			EndDo;
			
			// More containers than goods have been scanned, it is necessary to add a line of containers with an undistributed quantity.
			If QuantityForDistribution > 0 Then
				
				ProductLineToScan = VTProductsForScanning.Find(1, "ActiveString");
				
				If ProductLineToScan <> Undefined Then
					
					NewContainerLine = VTProductsForScanning.Insert(VTProductsForScanning.IndexOf(ProductLineToScan) + 1);
					
					FillPropertyValues(NewContainerLine, TareTableRow);
					
					NewContainerLine.Cell = Form.CurrentScanningLine.Cell;
					NewContainerLine.ZoomRatio = 1;
					
					NewContainerLine.NumberOfPackagingsScanned = Form.CurrentScanningLine.NumberOfPackagingsScanned *
						TareTableRow.Count;
					NewContainerLine.NumberOfPackagesDoNotShip = TareTableRow.Count *
						AdjustedNumberOfPackagesDoNotShip(NewContainerLine, PermissibleDeviationOfSelectedGoods);
					
					If (ModeSettings.JobType = "Recalculate" 
						Or ModeSettings.JobType = "PickingCheck"
						Or ModeSettings.JobType = "Receiving") Then
						
					ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
						If (JobType = "Filter"
								Or JobType = "Move")
							And SeriesAreIndicatedUponSelection(Form.CurrentScanningLine.BatchesIndicationStatus) Then
							
							FilterOfProducts_ = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber,
								|ValidUntil_");
							
						Else
							FilterOfProducts_ = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
						EndIf;
						
						FillPropertyValues(FilterOfProducts_, Form.CurrentScanningLine);
						
						ArrayOfRowsProductBalances = VTBalancesOfGoodsInCell.FindRows(FilterOfProducts_);
						
						If ArrayOfRowsProductBalances.Count() = 0 Then
							ProductLineIndex = 0;
						Else
							ProductLineIndex = VTBalancesOfGoodsInCell.IndexOf(ArrayOfRowsProductBalances[0]);
						EndIf;
						
						If ArrayOfTareRowsLeftovers.Count() = 0 Then
							NewRowOfBalances = VTBalancesOfGoodsInCell.Insert(ProductLineIndex + 1);
							FillPropertyValues(NewRowOfBalances, TareTableRow);
							
							SetUnitOfMeasurementOfTareGoodsResiduesOfGoodsInCell(NewRowOfBalances);
							NewRowOfBalances.BatchPresentation = SetSeriesPresentation(Form.CurrentScanningLine);
							
							NewRowOfBalances.Cell = FilterOfProducts_.Cell;
							NewRowOfBalances.QuantityScanned = Form.CurrentScanningLine.NumberOfPackagingsScanned *
								TareTableRow.Count;
						Else
							ArrayOfTareRowsLeftovers[0].QuantityScanned = ArrayOfTareRowsLeftovers[0].Count +
								Form.CurrentScanningLine.NumberOfPackagingsScanned * TareTableRow.Count;
								
							TareRowIndex = VTBalancesOfGoodsInCell.IndexOf(ArrayOfTareRowsLeftovers[0]);
							NumberOfOffsetRows = TareRowIndex - ProductLineIndex - 1;
							VTBalancesOfGoodsInCell.Move(ArrayOfTareRowsLeftovers[0], -NumberOfOffsetRows);
						EndIf;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Form.ValueToFormAttribute(VTProductsForScanning, "GoodsForScanning");
	ValueToFormData(VTBalancesOfGoodsInCell, Form.Object.StockOfGoodsInBin);
	
	// Since the number of rows in the product table for scanning has changed,
	// it is necessary to recalculate the service information - the number of products in the cell.
	FillInServiceInformationOfGoodsForScanning(Form);
	
EndProcedure

// Depending on the task type, adds the scanned container to the container table or to the product table.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure AddContainerForScannedProduct(Form)
	
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	ThisIsAProduct = ThisIsAProduct(Form.CurrentScanningLine);
	ThisIs_Recalculation = (JobType = "Recalculate");
	
	If Not Form.UseReusablePackage Then
		Return;
	EndIf;
	
	If Not ThisIsAProduct Then
		Return;
	EndIf;
	
	If ThisIs_Recalculation Then
		Return;
	EndIf;
	
	If ThisIsSetOfGoods Then
		AddContainersToScannedContainers(Form);
	Else
		AddSetContainerToProductsForScanning(Form);
	EndIf;
	
EndProcedure

// Called when switching to the scan parameter.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 	* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
// 		** ScanToEnterTheNumber - FormButton - a button that opens the product quantity entry form.
//
Procedure WhenGoingToScanOption(Form)
	
	Items = Form.Items;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	ScanParameter = Form.ModeSettings.ScanParameter;
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If JobType = "Location" Then
		
		Items.ScanToEnterTheNumber.Enabled = True;
		
		If Not ThisIsSetOfGoods
			And ThisIsProcessingOrderOfItemCell Then
			
			If Not (ScanParameter = "Cell"
				Or ScanParameter = "Count") Then
				
				Items.ScanToEnterTheNumber.Enabled = False;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets the next scan parameter from the parameter scan queue as current.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToNextScanOption(Form)
	
	ScanParameter  = Form.ModeSettings.ScanParameter;
	ScanningParameters = Form.ScanningParameters;
	
	UBound = (ScanningParameters.Count() - 1);
	
	StartScanning_ = False;
	If Not ValueIsFilled(ScanParameter) Then
		StartScanning_ = True;
		ScanParameterIndex = 0;
	EndIf;
	
	Filter = New Structure("ParameterName", ScanParameter);
	
	RowsArray = ScanningParameters.FindRows(Filter);
	If RowsArray.Count() = 0 Then
		ScanParameterIndex = 0;
	Else
		ScanParameterIndex = ScanningParameters.IndexOf(RowsArray[0]);
	EndIf;
	
	If ScanParameterIndex = UBound Then
		ScanParameterIndex = 0;
	Else
		If Not StartScanning_ Then
			ScanParameterIndex = ScanParameterIndex + 1;
		EndIf;
	EndIf;
	
	While Not ScanningParameters[ScanParameterIndex].Scan
		And Not (ScanParameterIndex > UBound) Do
		
		ScanParameterIndex = ScanParameterIndex + 1;
		
		If ScanParameterIndex > UBound Then
			ScanParameterIndex = 0;
		EndIf;
	EndDo;
	
	Form.ModeSettings.ScanParameter = ScanningParameters[ScanParameterIndex].ParameterName;
	
	WhenGoingToScanOption(Form);
	
EndProcedure

// Sets the scanned number of packages in the scanned products table.
// Called every time the number of scanned products changes - barcode scanning,
// or entering the quantity manually.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
// 	* ScannedGoods - FormDataCollection - table with information about scanned products.
//	AddToScannedProducts_ - Boolean - indicates whether data should be added to the <scanned Goods>TOR.
//  QuantityToAdd - Number - the number of products that will be used when adding a line to the TOR <scanned Goods>.
//  ThisIsDestinationChoice - Boolean
//
Procedure SetScannedQuantityOfGoods(Form, AddToScannedProducts_ = True,
	QuantityToAdd = 1, ThisIsDestinationChoice = False)
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	GoodsForScanning = Form.GoodsForScanning;
	ScannedGoods = Form.ScannedGoods;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	ThisIsPlacement = (JobType = "Location");
	ThisIsAcceptance = (JobType = "Receiving");
	ThisIs_Recalculation = (JobType = "Recalculate");
	
	If ThisIsSetOfGoods
		And (ThisIsPlacement 
			Or ThisIsAcceptance) Then
		
		Return;
		
	EndIf;
	
	If ThisIs_Recalculation Then
		Return;
	EndIf;
	
	If ProductSeriesIsInTask(Form, Form.CurrentScanningLine, Form.CurrentScanningLine.Series)
		Or SeriesAreIndicatedUponSelection(Form.CurrentScanningLine.BatchesIndicationStatus)
		And ProductIsInTask(Form, Form.CurrentScanningLine) Then
		
		If JobType = "PickingCheck"
			And Not ProductIsInTask(Form, Form.CurrentScanningLine) Then
			// It is not necessary to set the processed quantity for products from the list of tasks "Selection check".
		Else
			Filter = New Structure("ActiveString", 1);
			RowsArray = GoodsForScanning.FindRows(Filter);
			FillPropertyValues(RowsArray[0], CurrentScanningLine, 
				"NumberOfPackagingsScanned, NumberOfPackagesDoNotShip");
		EndIf;
		
	EndIf;
	
	SetNumberOfBalancesToProductBalancesInCell(Form, QuantityToAdd);
	
	If AddToScannedProducts_ Then
		
		If SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus) 
			And (ValueIsFilled(CurrentScanningLine.SKSeriesNumber)
				Or ValueIsFilled(CurrentScanningLine.SKIsGoodTo)) Then
			
			TBLString = ScannedGoods.Add();
			FillPropertyValues(TBLString, CurrentScanningLine);
			
			TBLString.Series = CurrentScanningLine.SkSeries;
			If QuantityToAdd = 1 Then
				TBLString.NumberOfPackagingsScanned = 1;
			Else
				TBLString.NumberOfPackagingsScanned = QuantityToAdd;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Writes lines describing actions of warehouse tasks
// in the appropriate case to the passed variables. It is used when forming texts of questions and warnings.
//
// Parameters:
//	JobType - String - job type,
//	ActionType - Undefined - variable that the action type is written to,
//	ExecutionType - Undefined - the variable that the execution type is written to.
//
Procedure GetActionType(JobType, ActionType, ExecutionType)
	
	If JobType = "Filter" Then
		
		ExecutionType = NStr("vi = 'lấy ra';
							|ru = 'отбора';
							|en = 'Picking'; fa = 'برداشت';
							|it = 'della selezione';
							|pl = 'filtru';
							|tr = 'filtre'");
		ActionType = NStr("vi = 'lọc';
							|ru = 'отбор';
							|en = 'Picking'; fa = 'برداشت';
							|it = 'selezione';
							|pl = 'filtr';
							|tr = 'filtre'");
		
	ElsIf JobType = "Location" Then
		
		ExecutionType = NStr("vi = 'sắp xếp';
							|ru = 'размещения';
							|en = 'Put-away'; fa = 'جای‌گذاری';
							|it = 'di collocamento';
							|pl = 'rozmieszczanie';
							|tr = 'yerleştirme'");
		ActionType = NStr("vi = 'sắp xếp';
							|ru = 'размещение';
							|en = 'Put-away'; fa = 'جای‌گذاری';
							|it = 'collocamento';
							|pl = 'lokalizacja';
							|tr = 'Yerleşim'");
		
	ElsIf JobType = "Move" Then
		
		ExecutionType = NStr("vi = 'điều chuyển';
							|ru = 'перемещения';
							|en = 'Transfer'; fa = 'انتقال';
							|it = 'di spostamento';
							|pl = 'przenoszenie';
							|tr = 'transfer'");
		ActionType = NStr("vi = 'điều chuyển';
							|ru = 'перемещение';
							|en = 'Transfer'; fa = 'انتقال';
							|it = 'spostamento';
							|pl = 'przemieszczenie';
							|tr = 'transfer'");
		
	ElsIf JobType = "Recalculate" Then
		
		ExecutionType = NStr("vi = 'kiểm đếm';
							|ru = 'пересчета';
							|en = 'Physical count'; fa = 'شمارش فیزیکی';
							|it = 'di ricalcolo';
							|pl = 'przeliczania';
							|tr = 'yeniden hesaplama'");
		ActionType = NStr("vi = 'kiểm đếm';
							|ru = 'пересчет';
							|en = 'Physical count'; fa = 'شمارش فیزیکی';
							|it = 'ricalcolo';
							|pl = 'przeliczenie';
							|tr = 'yeniden hesaplama'");
		
	ElsIf JobType = "PickingCheck" Then
		
		ExecutionType = NStr("vi = 'kiểm tra việc lấy ra';
							|ru = 'проверки отбора';
							|en = 'Follow-up check'; fa = 'بررسی پیگیری';
							|it = 'di verifica della selezione';
							|pl = 'weryfikacje wyboru';
							|tr = 'filtre kontrolü'");
		ActionType = NStr("vi = 'kiểm tra việc lấy ra';
							|ru = 'проверку отбора';
							|en = 'Follow-up check'; fa = 'بررسی پیگیری';
							|it = 'verifica della selezione';
							|pl = 'weryfikację wyboru';
							|tr = 'filtre kontrolü'");
		
	ElsIf JobType = "Receiving" Then
		
		ExecutionType = NStr("vi = 'nhập hàng';
							|ru = 'приемки';
							|en = 'Goods receipt'; fa = 'رسید انبار';
							|it = 'di accettazione';
							|pl = 'odbiory';
							|tr = 'kabuller'");
		ActionType = NStr("vi = 'nhập hàng';
							|ru = 'приемку';
							|en = 'Goods receipt'; fa = 'رسید انبار';
							|it = 'accettazione';
							|pl = 'odbiór';
							|tr = 'kabul'");
		
	EndIf;
	
EndProcedure

// Checks whether the current scan line is the last line in the scan queue.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - True if the scanned item line is the last one in the warehouse task.
//
Function ThisIsLastLineOfScan(Form)
	
	GoodsForScanning = Form.GoodsForScanning;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If CurrentScanningLine = Undefined Then
		Return False;
	EndIf;
	
	Filter = New Structure("ActiveString", 1);
	
	RowsArray = GoodsForScanning.FindRows(Filter);
	
	If RowsArray.Count() = 0 Then
		Return False;
	EndIf;
	
	UBound = GoodsForScanning.Count() - 1;
	
	Return (GoodsForScanning.IndexOf(RowsArray[0]) = UBound);
	
EndFunction

// Switches the scanning process to the next cell. Used, for example, when recalculating products,
// when scanning products in a cell is completed and you need to go to the next one.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	AddGoods - Boolean
//
Procedure GoToTheNextBin(Form, AddGoods = False)
	
	Items = Form.Items;
	WebServiceMode = Form.WebServiceMode;
	ModeSettings = Form.ModeSettings;
	JobType = Form.ModeSettings.JobType;
	GoodsForScanning = Form.GoodsForScanning;
	CellsForScanning = Form.CellsForScanning;
	
	If Form.CurrentScanningLine = Undefined Then
		
		Form.CurrentScanningLine = ScanLine();
		
		If ModeSettings.JobType = "Recalculate" Then
			TraceCell = GoodsForScanning[0];
			ModeSettings.ScanParameter = "Cell";
			
			FillPropertyValues(Form.CurrentScanningLine, TraceCell, "Cell, CellCode, NumberOfBins, CellNumber");
		EndIf;
	Else
		
		If JobType = "Recalculate" Then
			
			Filter = New Structure("Cell", Form.CurrentScanningLine.Cell);
			
			RowsArray = CellsForScanning.FindRows(Filter);
			If RowsArray.Count() = 0 Then
				TraceCell = CellsForScanning[0];
			Else
				CurCell = RowsArray[0];
				CurCell.Scanned = 1;
				TraceCell = CellsForScanning[CellsForScanning.IndexOf(CurCell) + 1];
			EndIf;
			
			VTScannedProducts = Form.FormAttributeToValue("ScannedGoods");
			
			// If you scanned a cell, but did not scan the item, then the cell is empty.
			// Let's write down an empty cell or find an un-scanned item in this cell and
			// write it down with zero remainder.
			If ValueIsFilled(Form.CurrentScanningLine.SKCell)
				And Not ValueIsFilled(Form.CurrentScanningLine.SKProducts) Then
				
				TheStructureOfTheSearch = New Structure;
				TheStructureOfTheSearch.Insert("Cell", Form.CurrentScanningLine.Cell);
				
				VTProductsForScanning = Form.FormAttributeToValue("GoodsForScanning");
				
				ArrayOfProductsToScanByCurCell = VTProductsForScanning.FindRows(TheStructureOfTheSearch);
				For Each ArrayRow In ArrayOfProductsToScanByCurCell Do
					NewRow = VTScannedProducts.Add();
					FillPropertyValues(NewRow, ArrayRow, , "NumberOfPackagingsScanned");
				EndDo;
				
				// If you have scanned at least some item, then in the current cell we will find the item
				// that was planned to be scanned, but not scanned, and write it down with zero remainder.
			ElsIf ValueIsFilled(Form.CurrentScanningLine.SKCell)
				And ValueIsFilled(Form.CurrentScanningLine.SKProducts) Then
				
				TheStructureOfTheSearch = New Structure;
				TheStructureOfTheSearch.Insert("Cell", Form.CurrentScanningLine.Cell);
				
				VTProductsForScanning = Form.FormAttributeToValue("GoodsForScanning");
				
				ArrayOfProductsToScanByCurCell = VTProductsForScanning.FindRows(TheStructureOfTheSearch);
				For Each RowOfArrayOfProductsToScan In ArrayOfProductsToScanByCurCell Do
					
					Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
					FillPropertyValues(Filter, RowOfArrayOfProductsToScan);
					
					RowsArray = VTScannedProducts.FindRows(Filter);
					
					If RowsArray.Count() = 0 Then
						NewRow = VTScannedProducts.Add();
						FillPropertyValues(NewRow, RowOfArrayOfProductsToScan, , "NumberOfPackagingsScanned");
					Else
						Continue;
					EndIf;
					
				EndDo;
				
			EndIf;
			
			Form.ValueToFormAttribute(VTScannedProducts, "ScannedGoods");
			Form.CurrentScanningLine = ScanLine();
			
			FillPropertyValues(Form.CurrentScanningLine, TraceCell, "Cell, NumberOfBins, CellNumber");
			
			If WebServiceMode Then
				Filter = New Structure("Cell", TraceCell.Cell);
				RowsArray = GoodsForScanning.FindRows(Filter);
				
				Form.CurrentScanningLine.CellCode = RowsArray[0].CellCode;
			EndIf;
			
			WhenMovingToNextCellRemainingItemsInCell(Form, Form.CurrentScanningLine);
			
			ResetSignsOfScanningAllParameters(Form);
			SetParameterScanFlag(Form, "Cell", True);
			GoToNextScanOption(Form);
			
		ElsIf JobType = "Location" Then
			
			Filter = New Structure("ActiveString", 1);
			RowsArray = GoodsForScanning.FindRows(Filter);
			
			If RowsArray.Count() <> 0 Then
				If RowsArray[0].NumberOfPackages <> 0 Then
					AddContainerForScannedProduct(Form);
				EndIf;
			Else
				AddContainerForScannedProduct(Form);
			EndIf;
			
			If AddGoods Then
				AddItemsNotSelectedToTableForScanningItems(Form, True);
			EndIf;
			
			Filter = New Structure("Cell", Form.CurrentScanningLine.Cell);
			RowsArray = CellsForScanning.FindRows(Filter);
			
			CurCell = RowsArray[0];
			CurCell.Scanned = 1;
			
			Filter = New Structure("Cell", CellsForScanning[CellsForScanning.IndexOf(CurCell) + 1].Cell);
			RowsArray = GoodsForScanning.FindRows(Filter);
			TraceScanLine = RowsArray[0];
			
			ResetMarkOfActiveLineOfScanItems(GoodsForScanning);
			SetScanLineActivity(TraceScanLine);
			
			Form.CurrentScanningLine = ScanLine();
			FillPropertyValues(Form.CurrentScanningLine, TraceScanLine);
			
			WhenMovingToNextCellRemainingItemsInCell(Form, Form.CurrentScanningLine);
			
			ResetSignsOfScanningAllParameters(Form);
			SetParameterScanFlag(Form, "Cell", True);
			GoToNextScanOption(Form);
			
		ElsIf JobType = "Move" Then
			
			AddContainerForScannedProduct(Form);
			
			Filter = New Structure("Cell", Form.CurrentScanningLine.Cell);
			RowsArray = CellsForScanning.FindRows(Filter);
			
			CurCell = RowsArray[0];
			CurCell.Scanned = 1;
			
			Filter = New Structure("Cell", CellsForScanning[CellsForScanning.IndexOf(CurCell) + 1].Cell);
			RowsArray = GoodsForScanning.FindRows(Filter);
			TraceScanLine = RowsArray[0];
			
			ResetMarkOfActiveLineOfScanItems(GoodsForScanning);
			SetScanLineActivity(TraceScanLine);
			
			Form.CurrentScanningLine = ScanLine();
			FillPropertyValues(Form.CurrentScanningLine, TraceScanLine);
			
			WhenMovingToNextCellRemainingItemsInCell(Form, Form.CurrentScanningLine);
			
			ResetSignsOfScanningAllParameters(Form);
			SetParameterScanFlag(Form, "Cell", True);
			GoToNextScanOption(Form);
			
		Else
			
			Filter = New Structure("ActiveString", 1);
			RowsArray = GoodsForScanning.FindRows(Filter);
			
			If RowsArray.Count() <> 0 Then
				If RowsArray[0].NumberOfPackages <> 0 Then
					AddContainerForScannedProduct(Form);
				EndIf;
			Else
				AddContainerForScannedProduct(Form);
			EndIf;
			
			If AddGoods Then
				AddItemsNotSelectedToTableForScanningItems(Form, True);
			EndIf;
			
			Filter = New Structure("Cell", Form.CurrentScanningLine.Cell);
			RowsArray = CellsForScanning.FindRows(Filter);
			
			CurCell = RowsArray[0];
			CurCell.Scanned = 1;
			
			Filter = New Structure("Cell", CellsForScanning[CellsForScanning.IndexOf(CurCell) + 1].Cell);
			RowsArray = GoodsForScanning.FindRows(Filter);
			TraceScanLine = RowsArray[0];
			
			ResetMarkOfActiveLineOfScanItems(GoodsForScanning);
			SetScanLineActivity(TraceScanLine);
			
			Form.CurrentScanningLine = ScanLine();
			FillPropertyValues(Form.CurrentScanningLine, TraceScanLine);
			
			WhenMovingToNextCellRemainingItemsInCell(Form, Form.CurrentScanningLine);
			
			ResetSignsOfScanningAllParameters(Form);
			SetParameterScanFlag(Form, "Cell", True);
			GoToNextScanOption(Form);
			
		EndIf;
		
	EndIf;
	
	If Items.FormPages.CurrentPage <> Items.ScanPage Then
		GoToPage3(Form,"ScanPage");
	EndIf;
	
EndProcedure

// Positions the scan queue to the nearest UN-scanned row
// in the product table for scanning.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure GoToNearestNonScannedProductLine(Form)
	
	RowFound = False;
	GoodsForScanning = Form.GoodsForScanning;
	
	For Each TBLString In GoodsForScanning Do
		If TBLString.NumberOfPackagingsScanned <> TBLString.NumberOfPackagesInDocument Then
			RowFound = True;
			Break;
		EndIf;
	EndDo;
	
	If Not RowFound Then
		Return;
	EndIf;
	
	CurrentScanningLine = ScanLine();
	
	FillPropertyValues(CurrentScanningLine, TBLString);
	ClearScannedProductFields(CurrentScanningLine);
	ResetMarkOfActiveLineOfScanItems(GoodsForScanning);
	SetScanLineActivity(TBLString);
	
	CurrentScanningLine.NumberOfPackagesPut = CurrentScanningLine.NumberOfPackagingsScanned;
	
	SetParameterScanFlag(Form, "Series", SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus));
	
	Form.CurrentScanningLine = CurrentScanningLine;
	
EndProcedure

// Reads data from the next line in the list to scan and loads it into the structure
// of the current scan line.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	AddGoods - Boolean
//
Procedure GoToNextScanLineOfJob(Form, AddGoods = False)
	
	Barcode = "";
	QuantityByBarcode = 0;
	JobType = Form.ModeSettings.JobType;
	GoodsForScanning = Form.GoodsForScanning;
	CurrentScanningLine = Form.CurrentScanningLine;
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	
	If CurrentScanningLine = Undefined Then
		
		IndexOf = 0;
		
		TraceScanLine = GoodsForScanning[IndexOf];
		
		// Find the next un-scanned line in the scan queue.
		While (TaskLineScanned(TraceScanLine, Form.ModeSettings, PermissibleDeviationOfSelectedGoods))
			And (IndexOf < GoodsForScanning.Count() - 1) Do
			
			IndexOf = IndexOf + 1;
			TraceScanLine = GoodsForScanning[IndexOf];
			
		EndDo;
		
		CellHasNotChanged = False;
		ProductsHaveNotChanged = False;
		
	Else
		
		Barcode = CurrentScanningLine.Barcode;
		QuantityByBarcode = CurrentScanningLine.QuantityByBarcode;
		
		If Not JobType = "PickingCheck" Then
			AddContainerForScannedProduct(Form);
		EndIf;
		
		If AddGoods Then
			AddItemsNotSelectedToTableForScanningItems(Form, False);
		EndIf;
		
		// After adding the container, all the lines of the task may be completed.
		If AllJobLinesAreScanned(Form) Then
			WhenCurJobScanIsComplete(Form);
			Return;
		EndIf;
		
		Filter = New Structure("ActiveString", 1);
		
		RowsArray = GoodsForScanning.FindRows(Filter);
		If RowsArray.Count() = 0 Then
			IndexOf = 0;
		Else
			IndexOf = GoodsForScanning.IndexOf(RowsArray[0]) + 1;
		EndIf;
		
		TraceScanLine = GoodsForScanning[IndexOf];
		
		// Find the next un-scanned line in the scan queue.
		If Not ValueIsFilled(CurrentScanningLine.SKProducts) Then
			FilterOfProduct = New Structure("Cell, Products, Characteristic, Purpose, Package");
			FillPropertyValues(FilterOfProduct, CurrentScanningLine);
			
			ArrayOfStringsForProductList = GoodsForScanning.FindRows(FilterOfProduct);
			If ArrayOfStringsForProductList.Count() > 0 Then
				RowIndex = ArrayOfStringsForProductList.Count() - 1;
				LineOfProductList = ArrayOfStringsForProductList[RowIndex];
				
				If ThisIsTara(CurrentScanningLine) Then
					IndexOf = GoodsForScanning.IndexOf(LineOfProductList);
					If IndexOf < (GoodsForScanning.Count() - 1) Then
						TraceScanLine = GoodsForScanning[IndexOf + 1];
					Else
						TraceScanLine = GoodsForScanning[IndexOf];
					EndIf;
				Else
					IndexOf = GoodsForScanning.IndexOf(LineOfProductList);
					If IndexOf < (GoodsForScanning.Count() - 1) Then
						TraceScanLine = GoodsForScanning[IndexOf + 1];
					Else
						TraceScanLine = GoodsForScanning[IndexOf];
					EndIf;
				EndIf;
				
			EndIf;
		EndIf;
		
		While (TaskLineScanned(TraceScanLine, Form.ModeSettings, PermissibleDeviationOfSelectedGoods))
			And (IndexOf < GoodsForScanning.Count() - 1) Do
			
			IndexOf = IndexOf + 1;
			TraceScanLine = GoodsForScanning[IndexOf];
			
		EndDo;
		
		If (IndexOf = (GoodsForScanning.Count() - 1))
			And (TraceScanLine.NumberOfPackages = TraceScanLine.NumberOfPackagingsScanned) Then
			
			WhenCurJobScanIsComplete(Form);
			Return;
			
		EndIf;
		
		// Determine the signs - whether the cell, nomenclature, series has changed compared to the previous row.
		CellHasNotChanged = (CurrentScanningLine.SKCell = TraceScanLine.Cell);
		
		ProductsHaveNotChanged = (CurrentScanningLine.SKProducts = TraceScanLine.Products)
			And (CurrentScanningLine.SCCharacteristics = TraceScanLine.Characteristic)
			And (CurrentScanningLine.SkPackaging = TraceScanLine.Package);
		
	EndIf;
	
	If (CurrentScanningLine.QuantityOfGoodsInABin = CurrentScanningLine.GoodsNumberInTheBin)
		And Not ThisIsLastCell(Form) Then
		
		Filter = New Structure("Cell", CurrentScanningLine.Cell);
		RowsArray = Form.CellsForScanning.FindRows(Filter);
		
		CurCell_ = RowsArray[0];
		CurCell_.Scanned = 1;
		
	EndIf;
	
	ResetMarkOfActiveLineOfScanItems(GoodsForScanning);
	SetScanLineActivity(TraceScanLine);
	
	CurrentScanningLine = ScanLine();
	FillPropertyValues(CurrentScanningLine, TraceScanLine);
	
	WhenMovingToNextCellRemainingItemsInCell(Form, CurrentScanningLine);
	
	// Set the scanned fields if they have not changed from the previous row.
	CurrentScanningLine.SKCell = ?(CellHasNotChanged, CurrentScanningLine.Cell,
		Catalogs.StorageBins.EmptyRef());
	
	CurrentScanningLine.SKProducts = ?(ProductsHaveNotChanged, CurrentScanningLine.Products,
		Catalogs.Products.EmptyRef());
	
	CurrentScanningLine.SCCharacteristics = ?(ProductsHaveNotChanged, CurrentScanningLine.Characteristic,
		Catalogs.ItemsCharacteristics.EmptyRef());
	
	CurrentScanningLine.SkPackaging = ?(ProductsHaveNotChanged, CurrentScanningLine.Package,
		Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	CurrentScanningLine.Barcode = ?(ProductsHaveNotChanged, Barcode, "");
	CurrentScanningLine.QuantityByBarcode = ?(ProductsHaveNotChanged, QuantityByBarcode, 0);
	
	Form.CurrentScanningLine = CurrentScanningLine;
	
	// Configure the scan settings.
	ResetSignsOfScanningAllParameters(Form);
	Form.ModeSettings.ScanParameter = "";
	
	SetParameterScanFlag(Form, "Cell", Not CellHasNotChanged);
	SetParameterScanFlag(Form, "Products", ?(CellHasNotChanged, Not ProductsHaveNotChanged, True));
	SetParameterScanFlag(Form, "Series", SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus));
	
	GoToNextScanOption(Form);
	
	If Not (Form.Items.FormPages.CurrentPage = Form.Items.ScanPage) Then
		GoToPage3(Form, "ScanPage");
		Form.CurrentItem = ?(JobType = "Receiving"
									Or JobType = "PickingCheck",
								Form.Items.ScanTheProduct,
								Form.Items.ScanCell);
	EndIf;
	
EndProcedure

// Returns General information about the number of rows and cells in the table parts of the warehouse task.
// The values of product parameters are used when forming captions on scanning elements and calculating
// the progress of the task.
// 
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
// 	Structure - description of the product parameters of the warehouse task, which contains the following fields:
//	* NumberOfPackagesRecalculated - Number - the number of packages of the product to be recalculated in the warehouse cell.
//	* NumberOfPlacementPackages - Number - the number of packages of goods to be placed in the safe Deposit box inventory.
//	* NumberOfSelectionPackages - Number - the number of packages of goods to be selected from the storage cell.
//	* NumberOfRecalculationCells - Number - the number of storage cells in which you want to resample the goods.
//	* NumberOfPlacementCells - Number - the number of storage cells that you want to place items in.
//	* NumberOfSelectionCells_ - Number - the number of storage cells to select items from.
//	* NumberOfRecalculationLines - Number - the number of rows of recalculated items in accordance with the original
//											warehouse task.
//	* NumberOfPlacementLines - Number - the number of lines of items to be placed in accordance with the original
//											warehouse task.
//	* NumberOfSelectionLines - Number - the number of rows of selected items in accordance with the original
//										warehouse task.
//
Function TaskProductParameters(Form)
	
	DataProcessorObject = Form.Object;
	JobType = Form.ModeSettings.JobType;
	
	// To form the structure of the parameters of the goods.
	GoodsParameters = New Structure;
	
	GoodsParameters.Insert("NumberOfSelectionLines", 0);
	GoodsParameters.Insert("NumberOfPlacementLines", 0);
	GoodsParameters.Insert("NumberOfRecalculationLines", 0);
	
	GoodsParameters.Insert("NumberOfSelectionCells_", 0);
	GoodsParameters.Insert("NumberOfPlacementCells", 0);
	GoodsParameters.Insert("NumberOfRecalculationCells", 0);
	
	GoodsParameters.Insert("NumberOfSelectionPackages", 0);
	GoodsParameters.Insert("NumberOfPlacementPackages", 0);
	GoodsParameters.Insert("NumberOfPackagesRecalculated", 0);
	
	// When accepting goods under an order, the behavior of the form is similar
	// to the mode of a set of goods, so data on the parameters of goods is not required.
	If JobType = "Receiving" Then
		Return GoodsParameters;
	EndIf;
	
	GoodsParameters.NumberOfSelectionLines = DataProcessorObject.GoodsFilter.Count();
	GoodsParameters.NumberOfPlacementLines = DataProcessorObject.GoodsPlacement.Count();
	GoodsParameters.NumberOfRecalculationLines = DataProcessorObject.Goods.Count();
	
	GoodsParameters.NumberOfSelectionPackages = DataProcessorObject.GoodsFilter.Total("NumberOfPackages");
	GoodsParameters.NumberOfPlacementPackages = DataProcessorObject.GoodsPlacement.Total("NumberOfPackages");
	GoodsParameters.NumberOfPackagesRecalculated  = DataProcessorObject.Goods.Total("NumberOfPackages");
	
	Return GoodsParameters;
	
EndFunction

// Called when completing a set of products to create a new placement task.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CompleteTaskNewPlacement(Form)
	
	Object = Form.Object;
	ModeSettings = Form.ModeSettings;
	WebServiceMode = Form.WebServiceMode;
	ScannedGoods = Form.ScannedGoods;
	DZScannedContainer = Form.FormAttributeToValue("ScannedPackage");
	
	ThereAreScannedProducts = ThereAreScannedProducts(Form);
	
	If Not ThereAreScannedProducts Then
		CancelJobExecution(Form);
		Return;
	EndIf;
	
	If WebServiceMode Then
		JobParameters = WorkplaceOfWarehouseWorkerXDTO.CompleteTaskNewPlacement(Form);
	Else
		JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteTaskNewPlacement(
			Object.Warehouse, Object.Premise, ModeSettings.ReceivingArea, Object.Performer, ScannedGoods,
			DZScannedContainer);
	EndIf;
	
	If JobParameters.ReturnCode = 0 Then
		
		GoToMainMenuButton = NewDialogButton(
			"GoToWarehouseOperationSelection", 
			NStr("vi = 'Chuyển đến chọn giao dịch';
				|ru = 'Перейти к выбору операции';
				|en = 'Go to operation selection'; fa = 'Go to operation selection';
				|it = 'Passa alla selezione dell''operazione';
				|pl = 'Przejść do wyboru operacji';
				|tr = 'İşlem seçimine git'"));
		
		Buttons = New ValueList;
		Buttons.Add(GoToMainMenuButton);
		
		ShowMessageDialog(Form, JobParameters.MessageText, Buttons);
		
	Else
		ModeSettings.CreatedJob = JobParameters.Job;
		TakeTaskToWork(Form, ModeSettings.CreatedJob);
	EndIf;
	
EndProcedure

// Complements the container tree with subordinate packages, if the product packages are nested.
//
// Parameters:
//	StringPacking_ - ValueTreeRowCollection - node lines,
//	PackingKnot - CatalogRef.PackagesAndUnitsOfMeasure - the package for which subordinate packages are output,
//	PackingTable_ - ValueTable - packing table,
//	DocumentPackaging - ValueTable - document multi-turn packaging table,
//	AllContainersArePickedUp - Boolean - indicates whether the entire container is selected, including nested packages.
//
Procedure OutputSubordinatePackages(StringPacking_, PackingKnot, PackingTable_, DocumentPackaging, AllContainersArePickedUp)
	
	SubordinatePackages = PackingTable_.FindRows(New Structure("Parent", PackingKnot));
	QuantityOfProducts = StringPacking_.Parent.QuantityOfProducts;
	NumberOfProductsToDistribute = QuantityOfProducts;
	
	For Each CurRow In SubordinatePackages Do
		
		NewLinePackaging = StringPacking_.Add();
		FillPropertyValues(NewLinePackaging, CurRow);
		
		RemainingPackages = Int(QuantityOfProducts % CurRow.NumberOfPackages);
		
		NewLinePackaging.QuantityOfProducts = NewLinePackaging.QuantityOfProducts +
			?(RemainingPackages > 0 And RemainingPackages >= CurRow.MinimumNumberOfReusablePackages, 1, 0);
		
		NumberOfContainers = Int(NumberOfProductsToDistribute / CurRow.NumberOfPackages);
		ContainerResidue = Int(QuantityOfProducts % CurRow.NumberOfPackages);
		
		If NumberOfContainers > 0 Then
			
			NewLinePackaging.TheRecommendedNumberOfContainers = NumberOfContainers;
			NewLinePackaging.SelectedAmountOfPackaging = NewLinePackaging.TheRecommendedNumberOfContainers;
			NumberOfProductsToDistribute = ContainerResidue;
			
		EndIf;
		
		If CurRow = SubordinatePackages[SubordinatePackages.Count()-1] 
			And NumberOfProductsToDistribute > 0 Then
			
			NewLinePackaging.TheRecommendedNumberOfContainers =
				?(ValueIsFilled(NewLinePackaging.TheRecommendedNumberOfContainers), NewLinePackaging.TheRecommendedNumberOfContainers, 0)
				+ ?(NumberOfProductsToDistribute >= CurRow.MinimumNumberOfReusablePackages, 1, 0);
			NewLinePackaging.SelectedAmountOfPackaging = NewLinePackaging.TheRecommendedNumberOfContainers;
			
		EndIf;
		
		FillInNumberOfContainersFromDocument(DocumentPackaging, NewLinePackaging, AllContainersArePickedUp);
		
		OutputSubordinatePackages(
			NewLinePackaging.Rows,
			CurRow.Package,
			PackingTable_,
			DocumentPackaging,
			AllContainersArePickedUp);
		
	EndDo;
	
EndProcedure

// Fills the columns of the container quantity in the document's table With values based on the container data in the document.
//
// Parameters:
//	DocumentPackaging - ValueTable - summary table of containers,
//	TreeRow - ValueTreeRow - line wood containers,
//	AllContainersArePickedUp - Boolean - indicates that the entire container is filled.
//
Procedure FillInNumberOfContainersFromDocument(DocumentPackaging, TreeRow, AllContainersArePickedUp)
	
	UseVariants = Common.ObjectAttributeValue(TreeRow.ReusablePackageItems, "UseVariants");
	
	If UseVariants <> Enums.ItemVariantsUsageOptions.DontUse
		And Not ValueIsFilled(TreeRow.ReusablePackageVariant) Then
		
		TareDocumentStrings = DocumentPackaging.FindRows(
			New Structure(
				"Products, Warehouse, Date",
				TreeRow.ReusablePackageItems,
				TreeRow.Warehouse,
				TreeRow.Date));
		
	Else
		
		Filter = New Structure;
		
		Filter.Insert("Products", TreeRow.ReusablePackageItems);
		Filter.Insert("Characteristic", TreeRow.ReusablePackageVariant);
		Filter.Insert("Warehouse", TreeRow.Warehouse);
		Filter.Insert("Date", TreeRow.Date);
		
		TareDocumentStrings = DocumentPackaging.FindRows(Filter);
		
	EndIf;
	
	If TareDocumentStrings.Count() > 0 
		And TareDocumentStrings[0].NumberOfContainers > 0 Then
		
		TreeRow.NumberOfContainersInTheDocument = Min(TreeRow.TheRecommendedNumberOfContainers, TareDocumentStrings[0].NumberOfContainers);
		TareDocumentStrings[0].NumberOfContainers = TareDocumentStrings[0].NumberOfContainers - TreeRow.NumberOfContainersInTheDocument;
		TareDocumentStrings[0].TreeRow = TreeRow;
		
	EndIf;
	
	If TreeRow.NumberOfContainersInTheDocument <> TreeRow.SelectedAmountOfPackaging Then
		
		TreeRow.Selected_5 = True;
		AllContainersArePickedUp = False;
		
	EndIf;
	
EndProcedure

// Adds the selected container to the final container table.
//
// Parameters:
//	TreeRows - ValueTreeRowCollection - tare tree strings,
//	PackageTable - ValueTable - the final table of the container.
//
Procedure AddSelectedContainersToTable(TreeRows, PackageTable)
	
	For Each CurRow In TreeRows Do
		
		If CurRow.Selected_5 Then
			
			If ValueIsFilled(CurRow.ReusablePackageItems) Then
				
				NewRow = PackageTable.Add();
				NewRow.Products = CurRow.ReusablePackageItems;
				NewRow.Characteristic = CurRow.ReusablePackageVariant;
				NewRow.Count = CurRow.SelectedAmountOfPackaging;
				NewRow.Warehouse = CurRow.Warehouse;
				NewRow.Date = CurRow.Date;
				
			EndIf;
			
		EndIf;
		
		AddSelectedContainersToTable(CurRow.Rows, PackageTable);
		
	EndDo;
	
EndProcedure

// Adds a multi-turn container to the "scanned Goods" table.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Object - DocumentObject.GoodsReceiptNote - credit order.
//
Procedure AddReusablePackage(Form, Object)
	
	If Not Form.UseReusablePackage Then
		Return;
	EndIf;
	
	UseWarehouse = False;
	UseDate = False;
	
	// Get the goods table of the document.
	DocumentGoods = Object.Goods.Unload();
	
	DocumentGoods = New ValueTable();
	DocumentGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	DocumentGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	DocumentGoods.Columns.Add("Count", New TypeDescription("Number"));
	DocumentGoods.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	DocumentGoods.Columns.Add("Date", New TypeDescription("Date"));
	
	For Each CurRow In Object.Goods Do
		
		NewRow = DocumentGoods.Add();
		NewRow.Products = CurRow["Products"];
		NewRow.Characteristic = CurRow["Characteristic"];
		NewRow.Count = CurRow["Count"];
		
		If UseWarehouse Then
			NewRow.Warehouse = CurRow["Warehouse"];
		EndIf;
		
		If UseDate Then
			NewRow.Date = CurRow["Date"];
		EndIf;
		
	EndDo;
	
	DocumentGoods.GroupBy("Date, Products, Characteristic, Warehouse", "Count");
	
	// Create a container tree structure.
	Tara = New ValueTree();
	Tara.Columns.Add("Products");
	Tara.Columns.Add("Characteristic");
	Tara.Columns.Add("TheRecommendedNumberOfContainers");
	Tara.Columns.Add("UnitOfMeasure");
	Tara.Columns.Add("SelectedAmountOfPackaging");
	Tara.Columns.Add("QuantityOfProducts");
	Tara.Columns.Add("Package");
	Tara.Columns.Add("Selected_5", New TypeDescription("Boolean"));
	Tara.Columns.Add("ReusablePackageItems");
	Tara.Columns.Add("ReusablePackageVariant");
	Tara.Columns.Add("MinimumNumberOfReusablePackages");
	Tara.Columns.Add("NumberOfContainersInTheDocument");
	Tara.Columns.Add("AvailableContainerQuantity");
	Tara.Columns.Add("Warehouse");
	Tara.Columns.Add("Date");
	
	// Fill the multi-turn container tree.
	Query = New Query("
	|SELECT
	|	DocumentGoods.Products       AS Products,
	|	DocumentGoods.Characteristic     AS Characteristic,
	|	DocumentGoods.Count         AS Count,
	|	DocumentGoods.Warehouse              AS Warehouse,
	|	DocumentGoods.Date               AS Date
	|INTO
	|	TTDocumentProducts_
	|FROM
	|	&DocumentGoods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Count > 0
	|;
	|SELECT
	|	TTDocumentProducts_.Products                                  AS Products,
	|	TTDocumentProducts_.Characteristic                                AS Characteristic,
	|	TTDocumentProducts_.Warehouse                                         AS Warehouse,
	|	TTDocumentProducts_.Date                                          AS Date,
	|	0                                                               AS QuantityOfProducts,
	|	TTDocumentProducts_.Products.ReusablePackageItems   AS ReusablePackageItems,
	|	TTDocumentProducts_.Products.ReusablePackageVariant AS ReusablePackageVariant,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)          AS Package,
	|	0                                                               AS MinimumNumberOfReusablePackages
	|
	|INTO
	|	TTTare
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND TTDocumentProducts_.Products.SuppliedInReusablePackage
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocumentProducts_.Products                                  AS Products,
	|	TTDocumentProducts_.Characteristic                                AS Characteristic,
	|	TTDocumentProducts_.Warehouse                                         AS Warehouse,
	|	TTDocumentProducts_.Date                                          AS Date,
	|	TTDocumentProducts_.Count                                    AS QuantityOfProducts,
	|	VALUE(Catalog.Products.EmptyRef)                  AS ReusablePackageItems,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef)    AS ReusablePackageVariant,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)          AS Package,
	|	0                                                               AS MinimumNumberOfReusablePackages
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocumentProducts_.Products                                           AS Products,
	|	TTDocumentProducts_.Characteristic                                         AS Characteristic,
	|	TTDocumentProducts_.Warehouse                                                  AS Warehouse,
	|	TTDocumentProducts_.Date                                                   AS Date,
	|	CAST(TTDocumentProducts_.Count / &QueryTextPackagingFactor1 AS NUMBER(15,0)) AS QuantityOfProducts,
	|	ProductPackages.ReusablePackageItems                      AS ReusablePackageItems,
	|	ProductPackages.ReusablePackageVariant                    AS ReusablePackageVariant,
	|	ISNULL(ProductPackages.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	ProductPackages.MinimumNumberOfReusablePackages     AS MinimumNumberOfReusablePackages
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|LEFT JOIN
	|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|ON
	|	TTDocumentProducts_.Products.PackagingGroup = ProductPackages.Owner
	|	OR (TTDocumentProducts_.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|		AND TTDocumentProducts_.Products = ProductPackages.Owner)
	|	AND ProductPackages.SuppliedInReusablePackage
	|	AND NOT ProductPackages.DeletionMark
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|;
	|SELECT
	|	TTTare.Products                                                        AS Products,
	|	TTTare.Characteristic                                                      AS Characteristic,
	|	TTTare.Warehouse                                                               AS Warehouse,
	|	TTTare.Date                                                                AS Date,
	|	TTTare.Package                                                            AS Package,
	|	CASE
	|		WHEN
	|			TTTare.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.Complex)
	|		THEN
	|			TTTare.Package.NumberOfPackages
	|		ELSE
	|			&QueryTextPackagingFactor2
	|	END AS NumberOfPackages,
	|	TTTare.Package.Parent                                                   AS Parent,
	|	TTTare.Products.UnitOfMeasure                                       AS UnitOfMeasure,
	|	MAX(TTTare.MinimumNumberOfReusablePackages)           AS MinimumNumberOfReusablePackages,
	|	MAX(TTTare.ReusablePackageItems)                            AS ReusablePackageItems,
	|	MAX(TTTare.ReusablePackageVariant)                          AS ReusablePackageVariant,
	|	MAX(TTTare.QuantityOfProducts)                                    AS QuantityOfProducts
	|FROM
	|	TTTare AS TTTare
	|GROUP BY
	|	TTTare.Products,
	|	TTTare.Characteristic,
	|	TTTare.Warehouse,
	|	TTTare.Date,
	|	TTTare.Package
	|ORDER BY
	|	TTTare.Products,
	|	TTTare.Characteristic,
	|	TTTare.Warehouse,
	|	TTTare.Date,
	|	TTTare.Package
	|TOTALS
	|	MAX(ReusablePackageItems),
	|	MAX(ReusablePackageVariant)
	|BY
	|	TTTare.Products,
	|	TTTare.Characteristic,
	|	TTTare.Warehouse,
	|	TTTare.Date
	|;
	|SELECT
	|	TTDocumentProducts_.Products      AS Products,
	|	TTDocumentProducts_.Characteristic    AS Characteristic,
	|	TTDocumentProducts_.Warehouse             AS Warehouse,
	|	TTDocumentProducts_.Date              AS Date,
	|	SUM(TTDocumentProducts_.Count) AS InitialTareQuantity,
	|	SUM(TTDocumentProducts_.Count) AS NumberOfContainers,
	|	UNDEFINED                        AS TreeRow
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|GROUP BY
	|	TTDocumentProducts_.Products,
	|	TTDocumentProducts_.Characteristic,
	|	TTDocumentProducts_.Warehouse,
	|	TTDocumentProducts_.Date
	|ORDER BY
	|	TTDocumentProducts_.Products.Description,
	|	TTDocumentProducts_.Characteristic.Description,
	|	TTDocumentProducts_.Warehouse.Description,
	|	TTDocumentProducts_.Date
	|");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductPackages", Undefined));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TTTare.Package",
		"TTTare.Products"));
		
	Query.SetParameter("DocumentGoods", DocumentGoods);
	QueryResult = Query.ExecuteBatch();
	
	If QueryResult[2].IsEmpty() Then
		Return;
	EndIf;
	
	PackingTable_ = New ValueTable();
	PackingTable_.Columns.Add("Products");
	PackingTable_.Columns.Add("Characteristic");
	PackingTable_.Columns.Add("Package");
	PackingTable_.Columns.Add("Parent");
	PackingTable_.Columns.Add("QuantityOfProducts");
	PackingTable_.Columns.Add("NumberOfPackages");
	PackingTable_.Columns.Add("ReusablePackageItems");
	PackingTable_.Columns.Add("ReusablePackageVariant");
	PackingTable_.Columns.Add("MinimumNumberOfReusablePackages");
	
	AllContainersArePickedUp = True;
	
	SelectionOfProducts = QueryResult[2].Select(QueryResultIteration.ByGroups);
	DocumentPackaging = QueryResult[3].Unload();
	
	While SelectionOfProducts.Next() Do
		
		FeatureSelection_ = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		
		While FeatureSelection_.Next() Do
			
			SampleWarehouses = FeatureSelection_.Select(QueryResultIteration.ByGroups);
			
			While SampleWarehouses.Next() Do
				
				DateSelection = SampleWarehouses.Select(QueryResultIteration.ByGroups);
				
				While DateSelection.Next() Do
					
					PackageSelection = DateSelection.Select();
					
					PackingTable_.Clear();
					
					While PackageSelection.Next() Do
						
						If ValueIsFilled(PackageSelection.Package) Then
							
							NewLinePackaging = PackingTable_.Add();
							FillPropertyValues(NewLinePackaging, PackageSelection);
							
						Else
							
							NewRow = Tara.Rows.Add();
							FillPropertyValues(NewRow, PackageSelection);
							
							If ValueIsFilled(NewRow.ReusablePackageItems) Then
								
								NewRow.TheRecommendedNumberOfContainers = Int(NewRow.QuantityOfProducts);
								NewRow.SelectedAmountOfPackaging = NewRow.TheRecommendedNumberOfContainers;
								
								FillInNumberOfContainersFromDocument(DocumentPackaging, NewRow, AllContainersArePickedUp);
								
							EndIf;
							
						EndIf;
						
					EndDo;
					
					OutputSubordinatePackages(NewRow.Rows, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(),
						PackingTable_, DocumentPackaging, AllContainersArePickedUp);
					
				EndDo;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	For Each CurRow In DocumentPackaging Do
		
		If CurRow.InitialTareQuantity = CurRow.NumberOfContainers Then
			
			NewRow = Tara.Rows.Add();
			NewRow.ReusablePackageItems = CurRow.Products;
			NewRow.ReusablePackageVariant = CurRow.Characteristic;
			NewRow.NumberOfContainersInTheDocument = CurRow.NumberOfContainers;
			NewRow.Warehouse = CurRow.Warehouse;
			NewRow.Date = CurRow.Date;
			NewRow.Selected_5 = True;
			AllContainersArePickedUp = False;
			
		ElsIf CurRow.NumberOfContainers > 0 And CurRow.TreeRow <> Undefined Then
			
			CurRow.TreeRow.NumberOfContainersInTheDocument = CurRow.TreeRow.NumberOfContainersInTheDocument + CurRow.NumberOfContainers;
			
			If CurRow.TreeRow.NumberOfContainersInTheDocument <> CurRow.TreeRow.SelectedAmountOfPackaging Then
				CurRow.TreeRow.Selected_5 = True;
				AllContainersArePickedUp = False;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Place the container in the storage.
	PackageTable = New ValueTable();
	PackageTable.Columns.Add("Products");
	PackageTable.Columns.Add("Characteristic");
	PackageTable.Columns.Add("Count");
	PackageTable.Columns.Add("Warehouse");
	PackageTable.Columns.Add("Date");
	
	AddSelectedContainersToTable(Tara.Rows, PackageTable);
	
	PackageTable.GroupBy("Products,Characteristic,Warehouse,Date", "Count");
	
	AddressOfContainerInStorage = PutToTempStorage(PackageTable, Form.UUID);
	
	// Fill multi-turn containers from storage.
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		ActionStructureModifiedStrings);
	
	ParametersForSpecifyingSeriesInDocument = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptNote));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, ParametersForSpecifyingSeriesInDocument);
	
EndProcedure

// Called when a set of products is completed when goods are accepted.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CompleteAcceptanceTask(Form)
	
	Job = Form.ModeSettings.Job;
	
	HasErrors = False;
	DataProcessorIsRequired = False;
	ThereAreScannedProducts = ThereAreScannedProducts(Form);
	
	// If there are no scanned items, then cancel the task.
	If Not ThereAreScannedProducts Then
		CancelJobExecution(Form);
		Return;
	EndIf;
	
	DocumentObject = Job.GetObject();
	
	DocumentObject.Goods.Clear();
	
	For Each TBLString In Form.ScannedGoods Do
		
		// ... PM Goods
		LineProducts_ = DocumentObject.Goods.Add();
		FillPropertyValues(LineProducts_, TBLString);
		
		If TBLString.ZoomRatio <> 0 Then
			LineProducts_.Count = TBLString.NumberOfPackagingsScanned * TBLString.ZoomRatio;
		Else
			LineProducts_.Count = TBLString.NumberOfPackagingsScanned;
		EndIf;
		
		LineProducts_.NumberOfPackages = TBLString.NumberOfPackagingsScanned;
	EndDo;
	
	DocumentObject.Status = Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired;
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.GoodsReceiptNote);
	
	If Form.UsePackingLists Then
		PackingLists = DocumentObject.Goods.FindRows(New Structure("ThisIsAPackingList",True));
		Form.SeriesSpecificationParameters = SeriesSpecificationParameters;
		PackingListsServer.AddLinesOnPackingLists(Form, DocumentObject.Goods, PackingLists, DataProcessorIsRequired, True);
	EndIf;
	
	SelectingDeletedRows = New Structure("NumberOfPackages", 0);
	ArrayOfRowsToDelete_1 = DocumentObject.Goods.FindRows(SelectingDeletedRows);
	
	For Each RowToDelete In ArrayOfRowsToDelete_1 Do
		DocumentObject.Goods.Delete(RowToDelete);
	EndDo;
	
	AddReusablePackage(Form, DocumentObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
	
	If DocumentObject.WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	GoodsOfOrder.DocumentShipments  AS DocumentShipments,
		|	GoodsOfOrder.Products      AS Products,
		|	GoodsOfOrder.Characteristic    AS Characteristic,
		|	GoodsOfOrder.Purpose        AS Purpose,
		|	SUM(GoodsOfOrder.Count) AS Count
		|FROM
		|	Document.GoodsReceiptNote.Goods AS GoodsOfOrder
		|WHERE
		|	GoodsOfOrder.Ref = &Ref
		|	AND NOT GoodsOfOrder.ThisIsAPackingList
		|	AND GoodsOfOrder.PackingListParent = VALUE(Document.PackingList.EmptyRef)
		|	AND GoodsOfOrder.Count <> 0
		|	AND GoodsOfOrder.DocumentShipments <> UNDEFINED
		|
		|GROUP BY
		|	GoodsOfOrder.DocumentShipments,
		|	GoodsOfOrder.Products,
		|	GoodsOfOrder.Characteristic,
		|	GoodsOfOrder.Purpose";
		
		Query.SetParameter("Ref", Job);
		
		GoodsForShipment_ = Query.Execute().Unload();
		
		For Each ShippingLine In GoodsForShipment_ Do
			
			DistributionQuantity = ShippingLine.Count;
			
			FilterOfProducts_ = ?(Not ValueIsFilled(ShippingLine.Series),
							New Structure("Products, Characteristic, Purpose"),
							New Structure("Products, Characteristic, Purpose, Series"));
			FillPropertyValues(FilterOfProducts_, ShippingLine);
			
			DocumentRows = DocumentObject.Goods.FindRows(FilterOfProducts_);
			
			For Each DocumentLine In DocumentRows Do
				
				If ValueIsFilled(DocumentLine.DocumentShipments) Then
					Continue;
				EndIf;
				
				If DocumentLine.Count <= DistributionQuantity Then
					DocumentLine.DocumentShipments = ShippingLine.DocumentShipments;
					
					DistributionQuantity = DistributionQuantity - DocumentLine.Count;
				Else
					NewRow = DocumentObject.Goods.Add();
					FillPropertyValues(NewRow, DocumentLine);
					
					Count = DocumentLine.Count - DistributionQuantity;
					
					DocumentLine.DocumentShipments = ShippingLine.DocumentShipments;
					DocumentLine.Count       = DistributionQuantity;
					
					NewRow.Count = Count
				EndIf;
				
				If DistributionQuantity <= 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	GoodsOfOrder.DocumentShipments                           AS DocumentShipments,
		|	GoodsOfOrder.PackingList                            AS PackingList,
		|	GoodsOfOrder.PackingListParent                    AS PackingListParent,
		|	GoodsOfOrder.ThisIsAPackingList                         AS ThisIsAPackingList,
		|	GoodsOfOrder.ThisIsInternalRowOfEmptyPackingList AS ThisIsInternalRowOfEmptyPackingList,
		|	GoodsOfOrder.Barcode                                   AS Barcode,
		|	CAST(GoodsOfOrder.Products AS Catalog.Products) AS Products,
		|	GoodsOfOrder.Characteristic                             AS Characteristic,
		|	GoodsOfOrder.Purpose                                 AS Purpose,
		|	CAST(GoodsOfOrder.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
		|	GoodsOfOrder.Series                                      AS Series,
		|	GoodsOfOrder.BatchesIndicationStatus                        AS BatchesIndicationStatus,
		|	GoodsOfOrder.Count                                 AS Count
		|INTO Goods
		|FROM
		|	&Goods AS GoodsOfOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.DocumentShipments                           AS DocumentShipments,
		|	Goods.PackingList                            AS PackingList,
		|	Goods.PackingListParent                    AS PackingListParent,
		|	Goods.ThisIsAPackingList                         AS ThisIsAPackingList,
		|	Goods.ThisIsInternalRowOfEmptyPackingList AS ThisIsInternalRowOfEmptyPackingList,
		|	Goods.Barcode                                   AS Barcode,
		|	Goods.Products                               AS Products,
		|	Goods.Characteristic                             AS Characteristic,
		|	Goods.Purpose                                 AS Purpose,
		|	Goods.Package                                   AS Package,
		|	Goods.Series                                      AS Series,
		|	Goods.BatchesIndicationStatus                        AS BatchesIndicationStatus,
		|	Goods.Count                                 AS Count,
		|	CASE
		|		WHEN Goods.Count = 0
		|				OR &QueryTextPackagingFactor = 0
		|			THEN Goods.Count
		|		ELSE
		|			Goods.Count / &QueryTextPackagingFactor
		|	END                                             AS NumberOfPackages
		|FROM
		|	Goods AS Goods";
		
		Query.Text = StrReplace(Query.Text,
									"&QueryTextPackagingFactor",
									Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
										"Goods.Package", "Goods.Products"));
		
		Query.SetParameter("Goods", DocumentObject.Goods.Unload());
		
		DocumentObject.Goods.Load(Query.Execute().Unload());
		
	EndIf;
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	Goods.PackingList,
	|	Goods.Products,
	|	Goods.BatchesIndicationStatus,
	|	Goods.PackingListParent
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS Field1
	|FROM
	|	Goods AS Goods
	|WHERE
	|	(Goods.PackingList = VALUE(Document.PackingList.EmptyRef)
	|				AND Goods.Products = VALUE(Catalog.Products.EmptyRef)
	|			OR Goods.BatchesIndicationStatus IN (1, 3, 5, 7, 9, 11, 13, 15, 21, 23, 25, 27)
	|			OR Goods.PackingList <> VALUE(Document.PackingList.EmptyRef)
	|				AND NOT Goods.PackingList IN
	|						(SELECT
	|							Goods.PackingListParent
	|						FROM
	|							Goods))";
	
	Query.SetParameter("Goods",
		DocumentObject.Goods.Unload(, "PackingList, PackingListParent, Products, BatchesIndicationStatus"));
	
	If Query.Execute().IsEmpty()
		And Not DataProcessorIsRequired Then
		
		DataProcessorIsRequired = Not DocumentObject.CheckFilling();
		
		If Not DataProcessorIsRequired Then
			DocumentObject.Status = Enums.GoodsReceiptNoteStatuses.Accepted;
			
			SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.GoodsReceiptNote);
			ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
		EndIf;
		
	EndIf;
	
	// Record and hold the document.
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
	Except
		
		HasErrors = True;
		
		// Add an error entry to the log.
		JournalComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi kết thúc nhiệm vụ tiếp nhận đã xảy ra lỗi (xem nhật ký sự kiện). Mô tả lỗi: ""%1""';
				|ru = 'При завершении задания на приемку произошла ошибка (см.журнал регистрации). Описание ошибки: ""%1""';
				|en = 'Cannot complete Goods receipt task. For details, see the event log. Error: ""%1""'; fa = 'Cannot complete Goods receipt task. For details, see the event log. Error: ""%1""';
				|it = 'Durante il completamento del task di accettazione si è verificato un errore (vedi il registro). Descrizione dell''errore:""%1""';
				|pl = 'Przy zakończeniu zadania na odbiór wystąpił błąd (patrz dziennik rejestracji). Opis błędu: ""%1""';
				|tr = 'Kabul görevi tamamlanırken hata oluştu (kayıt deftere bakın). Hata ayrıntıları: ""%1""'"), 
			ErrorInfo().Description);
		
		WriteLogEvent(
			NStr("vi = 'Lỗi hoàn thành nhiệm vụ nhận.';
				|ru = 'Ошибка при завершении задания на приемку.';
				|en = 'Cannot complete Picking job.'; fa = 'Cannot complete Picking job.';
				|it = 'Errore durante il completamento del task di accettazione.';
				|pl = 'Błąd przy zakończeniu zadania na odbiór.';
				|tr = 'Kabul görevi tamamlanırken hata.'",
				Common.DefaultLanguageCode()), 
			EventLogLevel.Error, 
			Job.Metadata(), 
			Job, 
			JournalComment, 
			EventLogEntryTransactionMode.Transactional);
		
	EndTry;
	
	UnlockDataForEdit(Form.Job, Form.UUID);
	
	// Output a message to the user.
	
	If HasErrors Then
		MessageText = NStr("vi = 'Đã xảy ra lỗi khi hoàn tất nhiệm vụ tiếp nhận (xem nhật ký sự kiện).';
							|ru = 'При завершении задания на приемку произошла ошибка (см.журнал регистрации).';
							|en = 'Cannot complete Goods receipt task. For details, see the event log.'; fa = 'Cannot complete Goods receipt task. For details, see the event log.';
							|it = 'Durante il completamento del task di accettazione si è verificato un errore (vedi il registro).';
							|pl = 'Przy zakończeniu zadania na odbiór wystąpił błąd (patrz dziennik rejestracji).';
							|tr = 'Kabul görevi tamamlanırken hata oluştu (kayıt deftere bakın)'");
	ElsIf DataProcessorIsRequired Then
		MessageText = NStr("vi = 'Đã lưu các hàng hóa đã quét. Cần xử lý thêm lệnh.';
							|ru = 'Отсканированные товары сохранены. Требуется дополнительная обработка ордера.';
							|en = 'Scanned items are saved. The document requires further processing.'; fa = 'Scanned items are saved. The document requires further processing.';
							|it = 'Le merci scansionate sono state salvate. È richiesta elaborazione aggiuntiva del mandato.';
							|pl = 'Zeskanowane wiersze pozycji zostały zapisane. Wymagane jest dodatkowe opracowanie zlecenia.';
							|tr = 'Taranan ürünler kaydedildi. Ek emir işleme gereklidir.'");
	Else
		MessageText = NStr("vi = 'Đã nhập hàng thành công.';
							|ru = 'Приемка товаров успешно завершена.';
							|en = 'Goods receipt task completed.'; fa = 'Goods receipt task completed.';
							|it = 'L''accettazione delle merci completata con successo.';
							|pl = 'Odbiór towarów został zakończony pomyślnie.';
							|tr = 'Mal girişi başarıyla tamamlandı.'");
	EndIf;
	
	ShowMessageDialog(Form, MessageText, NewDialogButton("MainMenuAcceptance", NStr("vi = 'Chuyển đến lựa chọn nhiệm vụ nhập hàng';
																					|ru = 'Перейти к выбору задания на приемку';
																					|en = 'To goods receipt task selection'; fa = 'To goods receipt task selection';
																					|it = 'Passare alla selezione del task di accettazione';
																					|pl = 'Przejść do wyboru zadania na odbiór';
																					|tr = 'Kabul için görev seçimine git'")));
	
EndProcedure

// Called when the move task is completed.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure FinishTask(Form)
	
	ModeSettings = Form.ModeSettings;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	DataProcessorObject = Form.Object;
	GoodsForScanning = Form.GoodsForScanning;
	
	If Not SelectionScanned Then
		
		If Not AllJobLinesAreScanned(Form) Then
			AddContainerForScannedProduct(Form);
		EndIf;
		
		// The task is completed when the selected
		// goods are partially scanned, the goods for placement are not scanned at all.
		If Not ValueIsFilled(ModeSettings.ReceivingArea) Then
			GoToSelectionOfShipmentAcceptanceZone(Form, "ReceivingArea");
		Else
			CompleteWarehouseTask(Form);
		EndIf;
		
	Else
		
		If Not AllJobLinesAreScanned(Form) Then
			AddContainerForScannedProduct(Form);
		EndIf;
		
		// Check if the selected goods are not fully placed,
		// then the remaining ones should be taken to the shipping zone. If
		// the shipping zone is not defined, then go to the selection of the shipping zone.
		SelectedQuantity = 0;
		PlacedQuantity_ = 0;
		
		For Each RowOfGoods In DataProcessorObject.GoodsFilter Do
			SelectedQuantity = SelectedQuantity + RowOfGoods.NumberOfPackagesPicked *
				RowOfGoods.ZoomRatio;
		EndDo;
		
		For Each RowOfGoods In GoodsForScanning Do
			PlacedQuantity_ = PlacedQuantity_ + RowOfGoods.NumberOfPackagingsScanned *
				RowOfGoods.ZoomRatio;
		EndDo;
		
		If Not (SelectedQuantity = PlacedQuantity_) Then
			If Not ValueIsFilled(ModeSettings.ReceivingArea) Then
				GoToSelectionOfShipmentAcceptanceZone(Form, "ReceivingArea");
			Else
				CompleteWarehouseTask(Form);
			EndIf;
		Else
			CompleteWarehouseTask(Form);
		EndIf;
		
	EndIf;
	
EndProcedure

// Called when the job is finished checking the selection.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CompleteTaskCheckSelection(Form)
	
	ThereAreGoodsUnshipped = False;
	ThereAreScannedProducts = ThereAreScannedProducts(Form);
	
	If Not ThereAreScannedProducts Then
		CancelJobExecution(Form);
		Return;
	EndIf;
	
	ModeSettings = Form.ModeSettings;
	WebServiceMode = Form.WebServiceMode;
	Job = Form.ModeSettings.Job;
	ScannedGoods = Form.ScannedGoods;
	GoodsForScanning = Form.GoodsForScanning;
	Object = Form.Object;
	
	If WebServiceMode Then
		JobParameters = WorkplaceOfWarehouseWorkerXDTO.CompleteWarehouseTask(Form, Job);
	Else
		JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.CompleteTaskCheckSelection(
			Object.Warehouse, Object.Premise, Job, ScannedGoods, GoodsForScanning,
			Form.BinLocationWarehousingIsUsed);
	EndIf;
	
	ClearScanItems(Form);
	
	If JobParameters.ReturnCode = 0 Then
		
		// If there are records in the surplus table, then it is necessary to display a message
		// about which goods need to be left in the shipping zone.
		If JobParameters.Property("NotShippedGoods") Then
			ThereAreGoodsUnshipped = True;
			DisplayInformationAboutUnloadedProducts(Form, JobParameters.NotShippedGoods);
			
			MessageTitle = NStr("vi = 'Chú ý!';
								|ru = 'Внимание!';
								|en = 'Warning.'; fa = 'Warning.';
								|it = 'Attenzione!';
								|pl = 'Uwaga!';
								|tr = 'Dikkat!'");
			MessageText = "";
		Else
			MessageTitle = NStr("vi = 'Chưa thực hiện nhiệm vụ';
								|ru = 'Задание не выполнено';
								|en = 'Task not completed'; fa = 'Task not completed';
								|it = 'Task non eseguito';
								|pl = 'Zadanie nie wykonane';
								|tr = 'Görev gerçekleştirilemedi'");
			MessageText = JobParameters.MessageText;
		EndIf;
		
	Else
		MessageTitle = NStr("vi = 'Nhiệm vụ đã thực hiện';
							|ru = 'Задание выполнено';
							|en = 'Task completed'; fa = 'Task completed';
							|it = 'Task eseguito';
							|pl = 'Zadanie wykonane';
							|tr = 'Görev tamamlandı'");
		MessageText = JobParameters.MessageText;
	EndIf;
	
	Buttons = New ValueList;
	AddButtonToGoToTaskSelection(Buttons, ModeSettings.JobType);
	
	ShowMessageDialog(Form, MessageText, Buttons, MessageTitle, ThereAreGoodsUnshipped);
	
EndProcedure

// Called when the selection check task is executed. Displays a table
// with information about product surpluses.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	TableOfUnloaded - ValueTable,TabularSection - surplus table.
//
Procedure DisplayInformationAboutUnloadedProducts(Form, TableOfUnloaded)
	
	TabDoc = Form.InformationTable;
	
	TabDoc.Clear();
	
	TemplateName = NameOfTemplateForInformationAboutSurplusProducts(Form);
	Template = DataProcessors.WorkplaceOfWarehouseWorker.GetTemplate(TemplateName);
	
	AreaDescription_ = Template.GetArea("LongDesc");
	AreaHeaderOfRemainderTable = Template.GetArea("TableHeading");
	AreaTableRow = Template.GetArea("TableRow");
	
	TabDoc.Put(AreaDescription_);
	TabDoc.Put(AreaHeaderOfRemainderTable);
	
	For Each TBLString In TableOfUnloaded Do
		
		ProductText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1%2%3%4';
				|ru = '%1%2%3%4';
				|en = '%1%2%3%4'; fa = '%1%2%3%4';
				|it = '%1%2%3%4';
				|pl = '%1%2%3%4';
				|tr = '%1%2%3%4'"),
			TBLString.Products,
			?(ValueIsFilled(TBLString.Characteristic), ", " + TBLString.Characteristic, ""),
			?(ValueIsFilled(TBLString.Purpose), " , (purpose: " + TBLString.Purpose + ")", ""),
			?(ValueIsFilled(TBLString.Series), " , (series: " + TBLString.Series + ")", ""));
		
		TextQuantity = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2';
				|ru = '%1 %2';
				|en = '%1 %2'; fa = '%1 %2';
				|it = '%1 %2';
				|pl = '%1 %2';
				|tr = '%1 %2'"), 
			TBLString.NumberOfPackages, 
			TBLString.Package);
		
		AreaTableRow.Parameters.OwnGoods = ProductText;
		AreaTableRow.Parameters.Count = TextQuantity;
		
		TabDoc.Put(AreaTableRow);
		
	EndDo;
	
EndProcedure

// Checks whether there are UN-scanned items in the warehouse task.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - True, there are un-scanned goods of the warehouse task.
//
Function ThereAreProductsNotScanned(Form)
	
	If Form.ModeSettings.SetOfProducts_ Then
		Return False;
	EndIf;
	
	ThereAreNotScanned = Not (Form.GoodsForScanning.Total("NumberOfPackagingsScanned") = Form.GoodsForScanning.Total("NumberOfPackages"));
	
	Return ThereAreNotScanned;
	
EndFunction

// Checks whether the scanned items are in the warehouse task.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - True, there are scanned goods of the warehouse task.
//
Function ThereAreScannedProducts(Form)
	
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	JobType = Form.ModeSettings.JobType;
	
	ThereAreScanned = False;
	
	If ThisIsSetOfGoods Then
		ThereAreScanned = (Form.ScannedGoods.Count() > 0);
	Else
		If JobType = "Recalculate" Then
			ThereAreScanned = (Form.ScannedGoods.Count() > 0);
		ElsIf JobType = "PickingCheck" Then
			ThereAreScanned = (Form.ScannedGoods.Total("NumberOfPackagingsScanned") > 0);
		Else
			ThereAreScanned = (Form.GoodsForScanning.Total("NumberOfPackagingsScanned") > 0);
		EndIf;
	EndIf;
	
	Return ThereAreScanned;
	
EndFunction

// Switches the workplace to the pick-up/drop-off zone selection mode.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ReceivingAndShippingAreasCell - FormTable - a table that contains information about storage cells
//															that act as a receiving or shipping zone.
//	ZoneType - String - zone types - acceptance or shipment.
//
Procedure GoToSelectionOfShipmentAcceptanceZone(Form, ZoneType) Export
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	
	// Set the zone type.
	ModeSettings.SelectionOfShipmentAcceptanceZone = ZoneType;
	
	// Set the text of the column header of the cell for selecting the acceptance/shipment zone.
	If ZoneType = "ReceivingArea" Then
		
		FormTitleText = CaptionTextOfFormElementTitle("HeaderForAcceptanceZone", Form);
		CellColumnHeaderText = NStr("vi = 'Khu vực nhập hàng';
									|ru = 'Зона приемки';
									|en = 'Inbound area'; fa = 'ناحیه ورودی';
									|it = 'Area di accettazione';
									|pl = 'Miejsce odbioru';
									|tr = 'Boşaltma alanı'");
		
		Filter = New Structure("CellType", WarehousesClientServer.CellTypesAcceptance());
		Items.ReceivingShippingAreas.RowFilter = New FixedStructure(Filter);
		
	ElsIf ZoneType = "ShippingZone" Then
		
		FormTitleText = CaptionTextOfFormElementTitle("HeadingToShipmentZone", Form);
		CellColumnHeaderText = NStr("vi = 'Khu vực giao hàng';
									|ru = 'Зона отгрузки';
									|en = 'Outbound area'; fa = 'ناحیه خروجی';
									|it = 'Area di spedizione';
									|pl = 'Strefa wysyłki';
									|tr = 'Sevkiyat alanı'");
		
		Filter = New Structure("CellType", WarehousesClientServer.CellTypesShipment());
		Items.ReceivingShippingAreas.RowFilter = New FixedStructure(Filter);
		
	EndIf;
	
	// Set the headers of the elements.
	SetFormHeader(Form, FormTitleText);
	Items.ReceivingAndShippingAreasCell.Title = CellColumnHeaderText;
	
	GoToPage3(Form, "SelectAShippingAcceptanceZonePage");
	
EndProcedure

// Clears the product tables that are used for the task.
// Called when the task is put to work or when moving to the placement of the move task.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ClearScanItems(Form)
	
	Form.ModeSettings.Job = Undefined;
	
	Form.GoodsForScanning.Clear();
	Form.ScannedGoods.Clear();
	Form.ScannedPackage.GetItems().Clear();
	Form.CellsForScanning.Clear();
	Form.Object.StockOfGoodsInBin.Clear();
	
EndProcedure

// Deletes rows of products that were not selected from the product table for Scanning.
// Used when performing tasks on the move.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* GoodsForScanning - TabularSection - a table containing information about the scanned items in the warehouse task.
//
Procedure CancelItemsNotSelected(Form)
	
	Object = Form.Object;
	GoodsAreDistributed = True;
	ArrayOfSelectedContainers = New Array;
	Form.CurrentScanningLine = ScanLine();
	
	VTProductsSelection = Object.GoodsFilter.Unload();
	GoodsForScanning = Form.GoodsForScanning;
	
	VTProductsForScanning = GoodsForScanning.Unload();
	
	VTProductsSelection.GroupBy("Products, Characteristic, Purpose, Series, BatchNumber, ValidUntil_, Package,
		|ItemsType, ZoomRatio, MeasuredValueType", "CountPicked, NumberOfPackagesPicked");
	VTUnprocessedGoods = VTProductsSelection.CopyColumns();
	
	Filter = New Structure("Products, Characteristic, Purpose, Package, Series");
	SelectionWithoutSeries = New Structure("Products, Characteristic, Purpose, Package");
	FilterByStorageBin = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	
	For Each LineVtProductsSelection In VTProductsSelection Do
		
		If LineVtProductsSelection.NumberOfPackagesPicked = 0 Then
			Continue;
		EndIf;
		
		If ThisIsTara(LineVtProductsSelection) Then
			ArrayOfSelectedContainers.Add(LineVtProductsSelection);
			Continue;
		EndIf;
		
		FillPropertyValues(Filter, LineVtProductsSelection);
		FillPropertyValues(SelectionWithoutSeries, LineVtProductsSelection);
		
		RowsArray = VTProductsForScanning.FindRows(SelectionWithoutSeries);
		NumberOfPackagesPicked = LineVtProductsSelection.NumberOfPackagesPicked;
		
		If RowsArray.Count() = 0 Then
			NewRow = VTUnprocessedGoods.Add();
			FillPropertyValues(NewRow, LineVtProductsSelection);
			
			Continue;
		EndIf;
		
		If SeriesAreIndicatedUponSelection(RowsArray[0].BatchesIndicationStatus) Then
			
			For Each ProductLineToScan In RowsArray Do
				
				If NumberOfPackagesPicked = 0 Then
					Break;
				EndIf;
				
				// We check whether all the products are placed.
				If ProductLineToScan.NumberOfPackages = ProductLineToScan.NumberOfPackagingsScanned Then
					Continue;
				EndIf;
				
				ProductsWithoutSeries = GoodsForScanning.FindRows(SelectionWithoutSeries);
				
				For Each ProductWithoutSeries In ProductsWithoutSeries Do
					If ProductWithoutSeries.NumberOfPackages = ProductWithoutSeries.NumberOfPackagingsScanned Then
						Continue;
					EndIf;
					
					TSRow = ProductWithoutSeries;
					
					Break;
				EndDo;
				
				If Not (ValueIsFilled(ProductLineToScan.ValidUntil_)
					Or ValueIsFilled(ProductLineToScan.BatchNumber)) Then
					
					QuantityToCell		= 0;
					QuantityNotPlaced	= ProductLineToScan.NumberOfPackages
												- ProductLineToScan.NumberOfPackagingsScanned;
					
					// We distribute the placed quantity of goods.
					If NumberOfPackagesPicked >= QuantityNotPlaced Then
						QuantityToCell			= ProductLineToScan.NumberOfPackages
														- ProductLineToScan.NumberOfPackagingsScanned;
						NumberOfPackagesPicked	= NumberOfPackagesPicked - QuantityNotPlaced;
						
						TSRow.NumberOfPackagingsScanned = ProductLineToScan.NumberOfPackages;
						ProductLineToScan.NumberOfPackagingsScanned = ProductLineToScan.NumberOfPackages;
					Else
						QuantityToCell			= NumberOfPackagesPicked;
						NumberOfPackagesPicked	= 0;
						
						TSRow.NumberOfPackagingsScanned = QuantityToCell + TSRow.NumberOfPackagingsScanned;
						ProductLineToScan.NumberOfPackagingsScanned = QuantityToCell
																						+ ProductLineToScan.NumberOfPackagingsScanned;
					EndIf;
					
					FillPropertyValues(FilterByStorageBin, LineVtProductsSelection);
					FilterByStorageBin.Cell = ProductLineToScan.Cell;
					
					RowsWithSeries = VTProductsForScanning.FindRows(FilterByStorageBin);
					
					// We check the availability of products with the series
					If RowsWithSeries.Count() = 0 Then
						
						IndexOfNewRow = VTProductsForScanning.IndexOf(ProductLineToScan);
						TSNewlineIndex = GoodsForScanning.IndexOf(TSRow);
						
						NewRow = VTProductsForScanning.Insert(IndexOfNewRow + 1);
						NewLineTS = GoodsForScanning.Insert(TSNewlineIndex + 1);
						
						FillPropertyValues(NewRow, ProductLineToScan);
						FillPropertyValues(NewLineTS, TSRow);
						
						NewRow.Series = LineVtProductsSelection.Series;
						NewLineTS.Series = LineVtProductsSelection.Series;
						
						NewRow.ValidUntil_ = LineVtProductsSelection.ValidUntil_;
						NewLineTS.ValidUntil_ = LineVtProductsSelection.ValidUntil_;
						
						NewRow.BatchNumber = LineVtProductsSelection.BatchNumber;
						NewLineTS.BatchNumber = LineVtProductsSelection.BatchNumber;
						
						NewRow.NumberOfPackages = QuantityToCell;
						NewLineTS.NumberOfPackages = QuantityToCell;
						
						NewRow.NumberOfPackagingsScanned = QuantityToCell;
						NewLineTS.NumberOfPackagingsScanned = QuantityToCell;
						
					Else
						
						NewRow = RowsWithSeries[0];
						NewLineTS = GoodsForScanning.FindRows(FilterByStorageBin)[0];
						
						NewRow.NumberOfPackages = NewRow.NumberOfPackages + QuantityToCell;
						NewLineTS.NumberOfPackages = NewLineTS.NumberOfPackages + QuantityToCell;
						
						NewRow.NumberOfPackagingsScanned = NewRow.NumberOfPackagingsScanned + QuantityToCell;
						NewLineTS.NumberOfPackagingsScanned = NewLineTS.NumberOfPackagingsScanned + QuantityToCell;
						
					EndIf;
					
					TSRow.ActiveString = 1;
					NewRow.ActiveString = 1;
					
					FillPropertyValues(Form.CurrentScanningLine, ProductLineToScan);
					AddSetContainerToProductsForScanning(Form);
					
				EndIf;
				
			EndDo;
			
		Else
			
			ArrayOfRowsWithSeries = VTProductsForScanning.FindRows(Filter);
			
			For Each ProductLineToScan In ArrayOfRowsWithSeries Do
				
				If NumberOfPackagesPicked = 0 Then
					Break;
				EndIf;
				
				If ProductLineToScan.NumberOfPackages = ProductLineToScan.NumberOfPackagingsScanned Then
					Continue;
				EndIf;
				
				FillPropertyValues(FilterByStorageBin, ProductLineToScan);
				TSRow = GoodsForScanning.FindRows(FilterByStorageBin)[0];
				
				QuantityNotPlaced = ProductLineToScan.NumberOfPackages
											- ProductLineToScan.NumberOfPackagingsScanned;
				
				If NumberOfPackagesPicked >= QuantityNotPlaced Then
					NumberOfPackagesPicked = NumberOfPackagesPicked - QuantityNotPlaced;
					
					TSRow.NumberOfPackagingsScanned = ProductLineToScan.NumberOfPackages;
					ProductLineToScan.NumberOfPackagingsScanned = ProductLineToScan.NumberOfPackages;
				Else
					TSRow.NumberOfPackagingsScanned = NumberOfPackagesPicked + TSRow.NumberOfPackagingsScanned;
					ProductLineToScan.NumberOfPackagingsScanned = NumberOfPackagesPicked
																					+ ProductLineToScan.NumberOfPackagingsScanned;
					
					NumberOfPackagesPicked = 0;
				EndIf;
				
				TSRow.ActiveString = 1;
				ProductLineToScan.ActiveString = 1;
				
				FillPropertyValues(Form.CurrentScanningLine, ProductLineToScan);
				AddSetContainerToProductsForScanning(Form);
				
			EndDo;
			
		EndIf;
		
		If NumberOfPackagesPicked > 0 Then
			NewRow = VTUnprocessedGoods.Add();
			FillPropertyValues(NewRow, LineVtProductsSelection);
			
			NewRow.NumberOfPackagesPicked = NumberOfPackagesPicked;
			NewRow.CountPicked = NewRow.ZoomRatio * NumberOfPackagesPicked;
		EndIf;
		
	EndDo;
	
	ArrayOfUnallocatedGoods = New Array;
	NumberType = New TypeDescription("Number", , , New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	VTProductsForScanning = GoodsForScanning.Unload();
	
	VTProductsForScanning.Sort("ZoomRatio Asc");
	VTProductsForScanning.Columns.Add("QuantityScanned", NumberType);
	
	If VTUnprocessedGoods.Count() > 0 Then
		
		Filter           = New Structure("Products, Characteristic, Purpose, Series");
		SelectionWithoutSeries   = New Structure("Products, Characteristic, Purpose");
		FilterByPackage = New Structure("Products, Characteristic, Purpose, Package");
		WHSelection        = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
		
		For Each RawGoods_ In VTUnprocessedGoods Do
			
			If Not GoodsAreDistributed Then
				Break;
			EndIf;
			
			FillPropertyValues(Filter, RawGoods_);
			FillPropertyValues(SelectionWithoutSeries, RawGoods_);
			
			CountPicked = RawGoods_.CountPicked;
			NumberOfPackagesPicked = RawGoods_.NumberOfPackagesPicked;
			
			ArrayOfProducts_2 = VTProductsForScanning.FindRows(SelectionWithoutSeries);
			
			If SeriesAreIndicatedUponSelection(ArrayOfProducts_2[0].BatchesIndicationStatus) Then
				
				For Each ProductLineToScan In ArrayOfProducts_2 Do
					
					If CountPicked = 0 Then
						Break;
					EndIf;
					
					If RawGoods_.ZoomRatio > ProductLineToScan.ZoomRatio Then
						If RawGoods_.ZoomRatio % ProductLineToScan.ZoomRatio > 0 Then
							Continue;
						EndIf;
					Else
						If ProductLineToScan.ZoomRatio % RawGoods_.ZoomRatio > 0 Then
							Continue;
						EndIf;
					EndIf;
					
					Count = ProductLineToScan.NumberOfPackages * ProductLineToScan.ZoomRatio;
					QuantityScanned = ProductLineToScan.NumberOfPackagingsScanned *
						ProductLineToScan.ZoomRatio;
					
					// We check whether all the products are placed.
					If Count = QuantityScanned Then
						Continue;
					EndIf;
					
					FillPropertyValues(FilterByPackage, ProductLineToScan);
					GoodsByPackaging = GoodsForScanning.FindRows(FilterByPackage);
					
					For Each GoodsWithPackaging In GoodsByPackaging Do
						If GoodsWithPackaging.NumberOfPackages = GoodsWithPackaging.NumberOfPackagingsScanned Then
							Continue;
						EndIf;
						
						TSRow = GoodsWithPackaging;
						
						Break;
					EndDo;
					
					If Not (ValueIsFilled(ProductLineToScan.ValidUntil_)
						Or ValueIsFilled(ProductLineToScan.BatchNumber)) Then
						
						QuantityToCell			= 0;
						NumberOfPackagesPerCell	= 0;
						QuantityNotPlaced		= Count - QuantityScanned;
						
						// We distribute the placed quantity of goods.
						If CountPicked >= QuantityNotPlaced Then
							QuantityToCell			= Count - ProductLineToScan.QuantityScanned;
							NumberOfPackagesPerCell	= QuantityToCell / ProductLineToScan.ZoomRatio;
							CountPicked			= CountPicked - QuantityNotPlaced;
							
							ProductLineToScan.QuantityScanned = ProductLineToScan.QuantityScanned
																					+ QuantityToCell;
							
							TSRow.NumberOfPackagingsScanned = ProductLineToScan.NumberOfPackages;
							ProductLineToScan.NumberOfPackagingsScanned = ProductLineToScan.NumberOfPackages;
						Else
							PlacedQuantity		= CountPicked + QuantityScanned;
							QuantityToCell			= CountPicked;
							NumberOfPackagesPerCell	= QuantityToCell / ProductLineToScan.ZoomRatio;
							CountPicked			= 0;
							
							ProductLineToScan.QuantityScanned = PlacedQuantity;
							
							If Not ValueIsFilled(ProductLineToScan.Package)
								And DimensionalUnitsOfMeasurement.Find(ProductLineToScan.MeasuredValueType) <> Undefined Then
								
								TSRow.NumberOfPackagingsScanned = PlacedQuantity;
								ProductLineToScan.NumberOfPackagingsScanned = PlacedQuantity;
								
							Else
								PlacedNumberOfPackages	= Int(PlacedQuantity / ProductLineToScan.ZoomRatio);
								NumberOfPackagesPerCell		= Int(QuantityToCell / ProductLineToScan.ZoomRatio);
								
								TSRow.NumberOfPackagingsScanned = PlacedNumberOfPackages;
								ProductLineToScan.NumberOfPackagingsScanned = PlacedNumberOfPackages;
							EndIf;
						EndIf;
						
						FillPropertyValues(FilterByStorageBin, RawGoods_);
						FilterByStorageBin.Cell = ProductLineToScan.Cell;
						FilterByStorageBin.Package = ProductLineToScan.Package;
						
						RowsWithSeries = VTProductsForScanning.FindRows(FilterByStorageBin);
						
						// We check the availability of products with the series
						If RowsWithSeries.Count() = 0 Then
							
							IndexOfNewRow = VTProductsForScanning.IndexOf(ProductLineToScan);
							TSNewlineIndex = GoodsForScanning.IndexOf(TSRow);
							
							NewRow = VTProductsForScanning.Insert(IndexOfNewRow + 1);
							NewLineTS = GoodsForScanning.Insert(TSNewlineIndex + 1);
							
							FillPropertyValues(NewRow, ProductLineToScan);
							FillPropertyValues(NewLineTS, TSRow);
							
							NewRow.Series = RawGoods_.Series;
							NewLineTS.Series = RawGoods_.Series;
							
							NewRow.ValidUntil_ = RawGoods_.ValidUntil_;
							NewLineTS.ValidUntil_ = RawGoods_.ValidUntil_;
							
							NewRow.BatchNumber = RawGoods_.BatchNumber;
							NewLineTS.BatchNumber = RawGoods_.BatchNumber;
							
							NewRow.QuantityScanned = QuantityToCell;
							
							NewRow.NumberOfPackagingsScanned = NumberOfPackagesPerCell;
							NewLineTS.NumberOfPackagingsScanned = NumberOfPackagesPerCell;
							
						Else
							
							NewRow = RowsWithSeries[0];
							FillPropertyValues(WHSelection, NewRow);
							
							NewLineTS = GoodsForScanning.FindRows(WHSelection)[0];
							
							NewRow.QuantityScanned = NewRow.NumberOfPackagingsScanned * QuantityToCell;
							
							NewRow.NumberOfPackagingsScanned = NewRow.NumberOfPackagingsScanned + NumberOfPackagesPerCell;
							NewLineTS.NumberOfPackagingsScanned = NewRow.NumberOfPackagingsScanned;
							
						EndIf;
						
						TSRow.ActiveString = 1;
						NewRow.ActiveString = 1;
						
						FillPropertyValues(Form.CurrentScanningLine, ProductLineToScan);
						AddSetContainerToProductsForScanning(Form);
						
					EndIf;
					
				EndDo;
				
			Else
				
				ArrayOfRowsWithSeries = VTProductsForScanning.FindRows(Filter);
				
				For Each ProductLineToScan In ArrayOfRowsWithSeries Do
					
					If CountPicked = 0 Then
						Break;
					EndIf;
					
					If RawGoods_.ZoomRatio > ProductLineToScan.ZoomRatio Then
						If RawGoods_.ZoomRatio % ProductLineToScan.ZoomRatio > 0 Then
							Continue;
						EndIf;
					Else
						If ProductLineToScan.ZoomRatio % RawGoods_.ZoomRatio > 0 Then
							Continue;
						EndIf;
					EndIf;
					
					Count = ProductLineToScan.NumberOfPackages * ProductLineToScan.ZoomRatio;
					QuantityScanned = ProductLineToScan.NumberOfPackagingsScanned *
						ProductLineToScan.ZoomRatio;
					
					// We check whether all the products are placed.
					If Count = QuantityScanned Then
						Continue;
					EndIf;
					
					FillPropertyValues(WHSelection, ProductLineToScan);
					TSRow = GoodsForScanning.FindRows(WHSelection)[0];
					
					QuantityNotPlaced = Count - QuantityScanned;
					
					If CountPicked >= QuantityNotPlaced Then
						CountPicked = CountPicked - QuantityNotPlaced;
						
						ProductLineToScan.QuantityScanned = Count;
						
						TSRow.NumberOfPackagingsScanned = ProductLineToScan.NumberOfPackages;
						ProductLineToScan.NumberOfPackagingsScanned = ProductLineToScan.NumberOfPackages;
					Else
						PlacedQuantity = CountPicked + QuantityScanned;
						ProductLineToScan.QuantityScanned = PlacedQuantity;
						
						CountPicked = 0;
						
						If Not ValueIsFilled(ProductLineToScan.Package)
							And DimensionalUnitsOfMeasurement.Find(ProductLineToScan.MeasuredValueType) <> Undefined Then
							
							TSRow.NumberOfPackagingsScanned = PlacedQuantity;
							ProductLineToScan.NumberOfPackagingsScanned = PlacedQuantity;
							
						Else
							PlacedNumberOfPackages = Int(PlacedQuantity / ProductLineToScan.ZoomRatio);
							
							TSRow.NumberOfPackagingsScanned = PlacedNumberOfPackages;
							ProductLineToScan.NumberOfPackagingsScanned = PlacedNumberOfPackages;
						EndIf;
					EndIf;
					
					TSRow.ActiveString = 1;
					ProductLineToScan.ActiveString = 1;
					
					FillPropertyValues(Form.CurrentScanningLine, ProductLineToScan);
					AddSetContainerToProductsForScanning(Form);
					
				EndDo;
				
			EndIf;
			
			// Checks whether the selected product is fully distributed
			If CountPicked > 0 Then
				ArrayOfUnallocatedGoods.Add(RawGoods_);
				GoodsAreDistributed = False;
				
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	For Each RowOfProduct In VTProductsForScanning Do
		If RowOfProduct.QuantityScanned % RowOfProduct.ZoomRatio > 0 Then
			GoodsAreDistributed = False;
			Break;
		EndIf;
	EndDo;
	
	If Not GoodsAreDistributed Then
		Form.ModeSettings.GoodsAreDistributed = False;
		Return;
	EndIf;
	
	For Each SelectedContainers In ArrayOfSelectedContainers Do
		
		FillPropertyValues(Filter, SelectedContainers);
		LinesWithTara = GoodsForScanning.FindRows(Filter);
		
		CountPicked = 0;
		
		For Each TareString In LinesWithTara Do
			CountPicked = CountPicked + TareString.NumberOfPackagingsScanned;
		EndDo;
		
		QuantityNotPlaced = SelectedContainers.NumberOfPackagesPicked - CountPicked;
		If QuantityNotPlaced = 0 Then
			Continue;
		EndIf;
		
		For Each TareString In LinesWithTara Do
			
			If TareString.NumberOfPackages = TareString.NumberOfPackagingsScanned Then
				Continue;
			EndIf;
			
			NumberOfPages_1 = TareString.NumberOfPackages - TareString.NumberOfPackagingsScanned;
			
			If QuantityNotPlaced >= NumberOfPages_1 Then
				QuantityNotPlaced = QuantityNotPlaced - NumberOfPages_1;
				TareString.NumberOfPackagingsScanned = TareString.NumberOfPackages;
			Else
				
				TareString.NumberOfPackagingsScanned = TareString.NumberOfPackagingsScanned + QuantityNotPlaced;
				NumberOfPackagesPicked = 0;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ArrayOfRowsToDelete_1 = New Array;
	
	For Each String In GoodsForScanning Do
		
		String.ActiveString = 0;
		
		If SeriesAreIndicatedUponSelection(String.BatchesIndicationStatus)
			And Not (ValueIsFilled(String.Series)) Then
			
			ArrayOfRowsToDelete_1.Add(String);
			Continue;
			
		EndIf;
		
		If String.NumberOfPackagingsScanned = 0 Then
			ArrayOfRowsToDelete_1.Add(String);
		Else
			String.NumberOfPackages = String.NumberOfPackagingsScanned;
			String.NumberOfPackagesInDocument = String.NumberOfPackages;
			String.NumberOfPackagingsScanned = 0;
		EndIf;
	EndDo;
	
	For Each RowToDelete In ArrayOfRowsToDelete_1 Do
		GoodsForScanning.Delete(RowToDelete);
	EndDo;
	
	Form.CurrentScanningLine = Undefined;
	
EndProcedure

// Fills in the tables of goods and containers for scanning, goods and containers from the document-warehouse task.
// 
// Additional processing of the task lines is performed:
// - sorting of cells. This is necessary
// if the selection, placement, or relocation task was created
// manually. In this case, it is likely that the rows in the task will be "mixed",
// i.e. when performing such a task, the warehouse employee will have to approach
// the same cell several times.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	TabularSectionName -String - name of the product table part.
//
Procedure FillPrepareGoodsContainersForScanning(Form, TabularSectionName)
	
	DocumentGoods = Form.Object[TabularSectionName].Unload();
	ColumnLineNumber = DocumentGoods.Columns["LineNumber"]; // ValueTableColumn
	ColumnLineNumber.Name = "OriginalLineNumber";
	
	GoodsForScanning = Form.GoodsForScanning;
	GoodsForScanning.Clear();
	
	While DocumentGoods.Count() > 0 Do
		
		// Find all rows with a cell from the 1st row in the product table.
		TableRowProductsOfDocument = DocumentGoods[0];
		
		FilterParameters = New Structure("Cell", TableRowProductsOfDocument.Cell);
		
		// Put these lines in the order following each other.
		RowsArray = DocumentGoods.FindRows(FilterParameters);
		
		If RowsArray.Count() > 0 Then
			
			For Each ProductTableRow_ In RowsArray Do
				
				NewProductLine = GoodsForScanning.Add();
				FillPropertyValues(NewProductLine, ProductTableRow_);
				DocumentGoods.Delete(ProductTableRow_);
				
			EndDo;
			
		Else
			
			NewProductLine = GoodsForScanning.Add();
			FillPropertyValues(NewProductLine, TableRowProductsOfDocument);
			DocumentGoods.Delete(TableRowProductsOfDocument);
			
		EndIf;
		
	EndDo;
	
	If Form.UseReusablePackage Then
		
		// Now we need to "lower" the lines with the container down in each cell.
		UBound = GoodsForScanning.Count() - 1;
		PermutationIsDone = True;
		
		While PermutationIsDone Do
			
			PermutationIsDone = False;
			
			For CurIndex__ = 0 To UBound Do
				
				TBLString = GoodsForScanning[CurIndex__];
				
				If Not ThisIsTara(TBLString) Then
					Continue;
				EndIf;
				
				If CurIndex__ = UBound Then // the last line does not need to be checked.
					Continue;
				EndIf;
				
				// This is a container row, check the cell in the next row, matches the container cell,
				// and in the wake. there is a product in the cell.
				NextLineTBL = GoodsForScanning[CurIndex__ + 1];
				
				If Not ThisIsAProduct(NextLineTBL) Then
					Continue;
				EndIf;
				
				If NextLineTBL.Cell = TBLString.Cell Then
					
					// ... rearrange the rows.
					ScanProductLine = ScanLine();
					
					FillPropertyValues(ScanProductLine, NextLineTBL);
					FillPropertyValues(NextLineTBL, TBLString);
					FillPropertyValues(TBLString, ScanProductLine);
					
					PermutationIsDone = True;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the table of "product for Scanning" values with data about the products to be scanned.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure FillGoodsContainerForScanning(Form)
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	
	If JobType = "Filter" Then
		
		FillPrepareGoodsContainersForScanning(Form, "GoodsFilter");
		
	ElsIf JobType = "Location" Then
		
		FillPrepareGoodsContainersForScanning(Form, "GoodsPlacement");
		
	ElsIf JobType = "Move" Then
		
		If Not SelectionScanned Then
			FillPrepareGoodsContainersForScanning(Form, "GoodsFilter");
		Else
			FillPrepareGoodsContainersForScanning(Form, "GoodsPlacement");
			CancelItemsNotSelected(Form);
		EndIf;
		
	ElsIf JobType = "Recalculate" Then
		
		FillPrepareGoodsContainersForScanning(Form, "Goods");
		
	ElsIf JobType = "PickingCheck" Then
		
		FillPrepareGoodsContainersForScanning(Form, "ShippedGoods");
		
	EndIf;
	
EndProcedure

// Fills in the technical specification "Cellscan" on the form.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure FillCellsForScanning(Form)
	
	JobType = Form.ModeSettings.JobType;
	CellsForScanning = Form.CellsForScanning;
	GoodsForScanning = Form.GoodsForScanning;
	
	If JobType = "Receiving"
		Or JobType = "PickingCheck" Then
		
		Return;
		
	EndIf;
	
	CellsForScanning.Clear();
	
	Filter = New Structure("Cell");
	
	For Each SpecificationRow In GoodsForScanning Do
		
		FillPropertyValues(Filter, SpecificationRow);
		
		RowsArray = CellsForScanning.FindRows(Filter);
		
		If RowsArray.Count() = 0 Then
			
			NewRow = CellsForScanning.Add();
			
			NewRow.Cell = SpecificationRow.Cell;
			NewRow.Scanned = 0;
			NewRow.CellNumber = CellsForScanning.Count();
			
		EndIf;
		
	EndDo;
	
	NumberOfBins = CellsForScanning.Count();
	
	For Each SpecificationRow In CellsForScanning Do
		SpecificationRow.NumberOfBins = NumberOfBins;
	EndDo;
	
EndProcedure

// Returns a tree of values with service information about the table of products
// that will be queued for scanning. Service information is used
// for displaying in the scan elements (cell sequence number, product, number of cells).
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Function ProductTree(Form)
	
	GoodsForScanning = Form.GoodsForScanning;
	
	// Fill in the number of cells and the sequence number of the cell in the product scan table.
	ProductTree = New ValueTree;
	
	ProductTree.Columns.Add("RowCode");
	ProductTree.Columns.Add("Cell");
	ProductTree.Columns.Add("Products");
	ProductTree.Columns.Add("Characteristic");
	ProductTree.Columns.Add("Package");
	
	ProductTree.Columns.Add("NumberOfBins");
	ProductTree.Columns.Add("CellNumber");
	ProductTree.Columns.Add("GoodsNumberInTheBin");
	ProductTree.Columns.Add("QuantityOfGoodsInABin");
	
	FilterByStorageBin = New Structure("Cell");
	FilterByProduct = New Structure("Products, Characteristic, Package");
	
	For Each SpecificationRow In GoodsForScanning Do
		
		FillPropertyValues(FilterByStorageBin, SpecificationRow);
		
		FoundRows = ProductTree.Rows.FindRows(FilterByStorageBin);
		
		If FoundRows.Count() = 0 Then
			
			CellRow = ProductTree.Rows.Add();
			FillPropertyValues(CellRow, SpecificationRow, "Cell");
			
			CellRow.CellNumber = ProductTree.Rows.Count();
			
		Else
			
			CellRow = FoundRows[0];
			
		EndIf;
		
		FillPropertyValues(FilterByProduct, SpecificationRow);
		FoundRows = CellRow.Rows.FindRows(FilterByProduct);
		
		If FoundRows.Count() = 0 Then
			
			RowOfProduct = CellRow.Rows.Add();
			FillPropertyValues(RowOfProduct, SpecificationRow, "Cell, Products, Characteristic, Package");
			
			RowOfProduct.GoodsNumberInTheBin = CellRow.Rows.Count();
			
		EndIf;
		
	EndDo;
	
	For Each CellRow In ProductTree.Rows Do
		
		CellRow.NumberOfBins = ProductTree.Rows.Count();
		
		For Each RowOfProduct In CellRow.Rows Do
			
			RowOfProduct.NumberOfBins = CellRow.NumberOfBins;
			RowOfProduct.CellNumber = CellRow.CellNumber;
			RowOfProduct.QuantityOfGoodsInABin = CellRow.Rows.Count();
			
		EndDo;
		
	EndDo;
	
	Return ProductTree;
	
EndFunction

// Puts in each row of the table "product for Scanning" in the service fields the information
// that you want to display on the scan form (total number of cells, cell number, number of products, etc.).
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure FillInServiceInformationOfGoodsForScanning(Form)
	
	ProductTree = ProductTree(Form);
	
	Filter = New Structure("Cell, Products, Characteristic, Package");
	
	For Each TBLString In Form.GoodsForScanning Do
		
		// Fill in the cell number, number of cells and other service information.
		FillPropertyValues(Filter, TBLString);
		
		RowsArray = ProductTree.Rows.FindRows(Filter, True);
		If RowsArray.Count() = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(TBLString, RowsArray[0], "NumberOfBins, CellNumber, QuantityOfGoodsInABin,
			|GoodsNumberInTheBin");
		
	EndDo;
	
EndProcedure

// Fills in the value tables on the workplace form with the data required
// when scanning the job.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure FillInDataForScanningJob(Form)
	
	FillGoodsContainerForScanning(Form);
	FillCellsForScanning(Form);
	FillInServiceInformationOfGoodsForScanning(Form);
	
EndProcedure

// Sets the initial values of the borders and counter required to
// display the progress of the task.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetInitialStateOfJob(Form)
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	GoodsForScanning = Form.GoodsForScanning;
	
	Form.JobExecutionState = 0;
	
	Items.JobExecutionState.MinValue = 0;
	Items.JobExecutionState.MaxValue = 0;
	
	If JobType = "Recalculate" Then
		Max_Value = Form.CellsForScanning.Count();
	ElsIf JobType = "PickingCheck" Then
		Max_Value = GoodsForScanning.Total("NumberOfPackagesInDocument") -
			GoodsForScanning.Total("NumberOfPackagesDoNotShip");
	Else
		Max_Value = GoodsForScanning.Total("NumberOfPackages");
	EndIf;
	
	Items.JobExecutionState.MaxValue = Max_Value;
	
EndProcedure

// This function returns whether the scan item should be displayed
// depending on the task type.
// 
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	TagName - String - name of the element on the form.
//
// Returns:
//	Boolean - True is to display the element, False is not.
//
Function DisplayScanItem(Form, TagName)
	
	JobType = Form.ModeSettings.JobType;
	
	Show = False;
	
	If TagName = "Cell" Then
		If Not (JobType = "PickingCheck"
				Or JobType = "Receiving") Then
			
			Show = True;
			
		EndIf;
	ElsIf TagName = "QuantityOfGoodsInDocument" Then
		If JobType = "PickingCheck" Then
			Show = True;
		EndIf;
	EndIf;
	
	Return Show;
	
EndFunction

// The procedure sets the visibility of the scan elements on the form.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetVisibilityOfScanItems(Form)
	
	Items = Form.Items;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	// Set the visibility of the "Take" elements.
	Visibility_ = Not (JobType = "Recalculate" Or JobType = "Receiving" Or ThisIsSetOfGoods);
	
	Items.PageTake.Visible = Visibility_;
	Items.TheInscriptionToTake.Visible = Visibility_;
	Items.LabelNumberOfPackages.Visible = Visibility_;
	
	// Set the current page of the "Take/Postponed" group.
	If JobType = "Filter" 
		Or JobType = "Location"
		Or JobType = "Move" Then
		
		Items.PagesTakeDeferred.CurrentPage = Items.PageTake;
		
	ElsIf JobType = "PickingCheck" Then
		Items.PagesTakeDeferred.CurrentPage = Items.PageDeferred;
	Else
		Items.PagesTakeDeferred.CurrentPage = Items.PageDecoration;
	EndIf;
	
	If Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
		If JobType = "Receiving"
			Or (JobType = "Location"
				And ThisIsSetOfGoods) Then
			
			Items.PagesAdditionalInformationJobs.CurrentPage = Items.PageParametersOfScannedGoods;
			Form.WeightOfScannedGoods = String(0.000) + " " + String(String(Form.UnitOfMeasureForWeight));
			Form.ScannedGoodsAmount = String(0.000000) + " " + String(String(Form.UnitOfMeasureForVolume));
			
		ElsIf JobType = "Filter"
			Or JobType = "Move"
			Or (JobType = "Location"
				And Not ThisIsSetOfGoods) Then
			
			Items.PagesAdditionalInformationJobs.CurrentPage = Items.PageStockBalanceInStorageBins;
			
		ElsIf JobType = "Recalculate" Then
			Items.PagesAdditionalInformationJobs.CurrentPage = Items.PageGoodsForRecount;
		Else
			Items.PagesAdditionalInformationJobs.CurrentPage = Items.PageNoInformation;
		EndIf;
	EndIf;
	
	// Set the visibility of the cell.
	Items.ScanCell.Visible = DisplayScanItem(Form, "Cell");
	Items.ScanPurpose.Visible = Form.Object.UseOrderSupplyWithAssignment;
	SetVisibilityOfQuantityInDocument(Form);
	
EndProcedure

// Sets the default scan scheme.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetDefaultScanScheme(Form)
	
	If Not ChangingSeriesScanSchemeIsAvailable(Form) Then
		Form.SeriesScanMode = "ProductSeriesProduct";
	EndIf;
	
	SetParametersOfScanSchemeElements(Form);
	
EndProcedure

// Called when the selection of items is completed when the move task is completed.
// When you move can be selected only part of the goods when placing the goods
// should be issued for processing only a selected portion of the goods.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ProcessScannedGoodsForMoving(Form)
	
	Object = Form.Object;
	WebServiceMode = Form.WebServiceMode;
	GoodsForScanning = Form.GoodsForScanning;
	VTScannedProducts = Form.FormAttributeToValue("ScannedGoods");
	
	If WebServiceMode Then
		JobParameters = WorkplaceOfWarehouseWorkerXDTO.ProcessScannedGoodsForMoving(Form);
	Else
		JobParameters = WorkplaceOfWarehouseWorkerApplicationInterface.ProcessScannedGoodsForMoving(
			Form.ModeSettings.Job, GoodsForScanning, VTScannedProducts);
	EndIf;
	
	Object.GoodsFilter.Clear();
	CommonClientServer.SupplementTable(JobParameters.GoodsFilter, Object.GoodsFilter);
	
	Form.ModeSettings.SelectionScanned = True;
	
EndProcedure

// Displays information about the product's barcode.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	OwnGoods - Structure - information about the product.
//
Procedure DisplayInformationOnProductBarcode(Form, OwnGoods)
	
	DisplayProductInformation(Form, OwnGoods);
	SetFormHeader(Form, NStr("vi = 'Hàng hóa';
							|ru = 'Товар';
							|en = 'Item'; fa = 'قلم';
							|it = 'Merce';
							|pl = 'Item';
							|tr = 'Ürün'"));
	
	GoToPage3(Form, "RequestInformationPage");
	
EndProcedure

// Displays information based on the cell's barcode.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Cell - Structure - information about the cell.
//
Procedure DisplayInformationOnBarcodeOfCell(Form, Cell)
	
	OutputCellInformation(Form, Cell);
	SetFormHeader(Form, NStr("vi = 'Ô hàng';
							|ru = 'Ячейка';
							|en = 'Storage bin'; fa = 'محل نگهداری';
							|it = 'Cella';
							|pl = 'Storage bin';
							|tr = 'Hücre'"));
	
	GoToPage3(Form, "RequestInformationPage");
	
EndProcedure

// Displays information about the product in the table document field.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ProductParameters_1 - Structure - information about the product.
//
Procedure DisplayProductInformation(Form, ProductParameters_1)
	
	Object = Form.Object;
	TabDoc = Form.InformationTable;
	ModeSettings = Form.ModeSettings;
	WebServiceMode = Form.WebServiceMode;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	TabDoc.Clear();
	
	TemplateName = NameOfProductInformationTemplate(Form);
	Template = DataProcessors.WorkplaceOfWarehouseWorker.GetTemplate(TemplateName);
	
	GoodsInformation = WorkplaceOfWarehouseWorkerApplicationInterface.GoodsInformation(Object.Warehouse, Object.Premise,
		ProductParameters_1);
	
	If ValueIsFilled(GoodsInformation.ProductPicture_) Then
		
		Picture = GoodsInformation.ProductPicture_;
		
		ProductScope = Template.GetArea("ProductPicture_");
		ProductDrawing = ProductScope.Drawings.Get(0);
		
		If TypeOf(Picture) = Type("BinaryData") Then
			ProductDrawing.Picture = New Picture(Picture);
		Else
			ProductDrawing.Picture = Picture;
		EndIf;
		
		TabDoc.Put(ProductScope);
		
	EndIf;
	
	// Output the product description.
	AreaDescription_ = Template.GetArea("LongDesc");
	HeaderArea_Balance = Template.GetArea("TitleBalance");
	AreaHeaderOfRemainderTable = Template.GetArea("HeaderOfRemainderTable");
	AreaRowBalance = Template.GetArea("StringBalance");
	
	If WebServiceMode Then
		
		AreaDescription_.Parameters.Fill(ProductParameters_1);
		
		AreaDescription_.Parameters.Characteristic = CurrentScanningLine.ItemVariantName;
		
		If Not ValueIsFilled(ProductParameters_1.Package) Then
			If Not ValueIsFilled(CurrentScanningLine.UnitOfMeasure) Then
				AreaDescription_.Parameters.Package = NStr("vi = '<không>';
															|ru = '<нет>';
															|en = '<None>'; fa = '<None>';
															|it = '<no>';
															|pl = '<None>';
															|tr = '<hayır>'");
			Else
				AreaDescription_.Parameters.Package = CurrentScanningLine.UnitOfMeasureDescription;
			EndIf;
		Else
			AreaDescription_.Parameters.Package = CurrentScanningLine.PackageName;
		EndIf;
		
	Else
		
		AreaDescription_.Parameters.Fill(ProductParameters_1);
		
		If Not ValueIsFilled(ProductParameters_1.Package) Then
			If Not ValueIsFilled(ProductParameters_1.UnitOfMeasure) Then
				AreaDescription_.Parameters.Package = NStr("vi = '<không>';
															|ru = '<нет>';
															|en = '<None>'; fa = '<None>';
															|it = '<no>';
															|pl = '<None>';
															|tr = '<hayır>'");
			Else
				AreaDescription_.Parameters.Package = String(ProductParameters_1.UnitOfMeasure);
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(ProductParameters_1.Characteristic) Then
		AreaDescription_.Parameters.Characteristic = NStr("vi = '<chưa sử dụng>';
															|ru = '<не используются>';
															|en = '<Not used>'; fa = '<استفاده نمی‌شود>';
															|it = '<non vengono utilizzati>';
															|pl = '<nie jest używane>';
															|tr = '<kullanılmamaktadır>'");
	EndIf;
	
	If Not ValueIsFilled(ProductParameters_1.LongDesc) Then
		AreaDescription_.Parameters.Fill(New Structure("LongDesc", NStr("vi = '<không>';
																		|ru = '<нет>';
																		|en = '<None>'; fa = '<None>';
																		|it = '<no>';
																		|pl = '<None>';
																		|tr = '<hayır>'")));
	EndIf;
	
	If Not ValueIsFilled(ProductParameters_1.SKU) Then
		AreaDescription_.Parameters.SKU = NStr("vi = '<không>';
												|ru = '<нет>';
												|en = '<None>'; fa = '<None>';
												|it = '<no>';
												|pl = '<None>';
												|tr = '<hayır>'");
	EndIf;
	
	TabDoc.Put(AreaDescription_);
	
	// Withdraw the remaining product.
	TitleTextBalance = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Số dư, trong kho: 
			|""%1"", 
			|trong nhà kho: 
			|""%2""';
			|ru = 'Остатки, на складе: 
			|""%1"", 
			|в помещении: 
			|""%2""';
			|en = 'Warehouse:
			|""%1""
			|Wareroom:
			|""%2""'; fa = 'Warehouse:
			|""%1""
			|Wareroom:
			|""%2""';
			|it = 'Giacenze nel magazzino: 
			|""%1"", 
			| nel locale: 
			|""%2""';
			|pl = 'Pozostałości na magazynie: 
			|""%1"", 
			|w pomieszczeniu: 
			|""%2""';
			|tr = 'Stok bakiyeleri: 
			|""%1"", 
			|alanda: 
			|""%2""'"),
		?(WebServiceMode, ModeSettings.NameOfTheWarehouse, Object.Warehouse),
		?(WebServiceMode, ModeSettings.WareroomName, Object.Premise));
	
	HeaderArea_Balance.Parameters.TitleTextBalance = TitleTextBalance;
	
	TabDoc.Put(HeaderArea_Balance);
	TabDoc.Put(AreaHeaderOfRemainderTable);
	
	ProductResidues = GoodsInformation.ProductResidues;
	
	For Each RemainderLine_ In ProductResidues Do
		
		FillPropertyValues(AreaRowBalance.Parameters, RemainderLine_);
		AreaRowBalance.Parameters.Count = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2';
				|ru = '%1 %2';
				|en = '%1 %2'; fa = '%1 %2';
				|it = '%1 %2';
				|pl = '%1 %2';
				|tr = '%1 %2'"), RemainderLine_.Count, RemainderLine_.Package);
		
		TabDoc.Put(AreaRowBalance);
		
	EndDo;
	
EndProcedure

// Returns the name of the layout for generating information about product surpluses.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	String - name of the layout.
//
Function NameOfTemplateForInformationAboutSurplusProducts(Form)
	
	If Form.ScreenResolution = Enums.ScreenResolutions.Resolution240x320 Then
		Return "Information240x320";
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution320x320 Then
		Return "Information320x320";
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
		Return "Information480x640";
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the name of the layout for generating information about the cell.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	String - name of the layout.
//
Function NameOfCellInformationTemplate(Form)
	
	If Form.ScreenResolution = Enums.ScreenResolutions.Resolution240x320 Then
		Return "CellInformation240x320";
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution320x320 Then
		Return "CellInformation320x320";
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
		Return "CellInformation480x640";
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the name of the layout for generating product information.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	String - name of the layout.
//
Function NameOfProductInformationTemplate(Form)
	
	If Form.ScreenResolution = Enums.ScreenResolutions.Resolution240x320 Then
		Return "GoodsInformation240x320";
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution320x320 Then
		Return "GoodsInformation320x320";
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
		Return "GoodsInformation480x640";
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Displays information about the cell in a table document on the "Pageinformation" page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Cell - CatalogRef.StorageBins - cell.
//
Procedure OutputCellInformation(Form, Cell)
	
	Object = Form.Object;
	TabDoc = Form.InformationTable;
	ModeSettings = Form.ModeSettings;
	WebServiceMode = Form.WebServiceMode;
	
	TabDoc.Clear();
	
	TemplateName = NameOfCellInformationTemplate(Form);
	Template = DataProcessors.WorkplaceOfWarehouseWorker.GetTemplate(TemplateName);
	
	AreaDescription_ = Template.GetArea("LongDesc");
	AreaRowBalance = Template.GetArea("StringBalance");
	HeaderArea_Balance = Template.GetArea("TitleBalance");
	AreaHeaderOfRemainderTable = Template.GetArea("HeaderOfRemainderTable");
	
	AreaDescription_.Parameters.Fill(Cell);
	TabDoc.Put(AreaDescription_);
	
	// Withdraw the remaining product.
	TitleTextBalance = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Số dư, trong kho: 
			|""%1"", 
			|trong nhà kho: 
			|""%2""';
			|ru = 'Остатки, на складе: 
			|""%1"", 
			|в помещении: 
			|""%2""';
			|en = 'Warehouse:
			|""%1""
			|Wareroom:
			|""%2""'; fa = 'Warehouse:
			|""%1""
			|Wareroom:
			|""%2""';
			|it = 'Giacenze nel magazzino: 
			|""%1"", 
			| nel locale: 
			|""%2""';
			|pl = 'Pozostałości na magazynie: 
			|""%1"", 
			|w pomieszczeniu: 
			|""%2""';
			|tr = 'Stok bakiyeleri: 
			|""%1"", 
			|alanda: 
			|""%2""'"),
		?(WebServiceMode, ModeSettings.NameOfTheWarehouse, Object.Warehouse),
		?(WebServiceMode, ModeSettings.WareroomName, Object.Premise));
	
	HeaderArea_Balance.Parameters.TitleTextBalance = TitleTextBalance;
	
	TabDoc.Put(HeaderArea_Balance);
	TabDoc.Put(AreaHeaderOfRemainderTable);
	
	If WebServiceMode Then
		CellGoods = WorkplaceOfWarehouseWorkerXDTO.CellGoods(Form, Cell);
	Else
		CellGoods = WorkplaceOfWarehouseWorkerApplicationInterface.CellGoods(Object.Warehouse, Object.Premise, Cell);
	EndIf;
	
	For Each RowOfProduct In CellGoods Do
		
		ProductText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1%2%3';
																					|ru = '%1%2%3';
																					|en = '%1%2%3'; fa = '%1%2%3';
																					|it = '%1%2%3';
																					|pl = '%1%2%3';
																					|tr = '%1%2%3'"),
			?(WebServiceMode, RowOfProduct.ItemName, RowOfProduct.Products),
			?(ValueIsFilled(RowOfProduct.ItemVariantName), ", " + RowOfProduct.ItemVariantName, ""),
			?(ValueIsFilled(RowOfProduct.BatchName), " , (series: " + RowOfProduct.BatchName + ")", ""));
		
		TextQuantity = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 %2';
																					|ru = '%1 %2';
																					|en = '%1 %2'; fa = '%1 %2';
																					|it = '%1 %2';
																					|pl = '%1 %2';
																					|tr = '%1 %2'"),
			RowOfProduct.Count,
			?(ValueIsFilled(RowOfProduct.PackageName), 
				RowOfProduct.PackageName,
				RowOfProduct.UnitOfMeasureDescription));
		
		AreaRowBalance.Parameters.OwnGoods = ProductText;
		AreaRowBalance.Parameters.Count = TextQuantity;
		
		TabDoc.Put(AreaRowBalance);
		
	EndDo;
	
EndProcedure

// Adds a button to the list of buttons to go to the list of tasks.
//
// Parameters:
//	Buttons - ValueList - list of buttons
//	JobType - String - job type.
//
Procedure AddButtonToGoToTaskSelection(Buttons, JobType)
	
	If JobType = "Filter" Then
		
		GoButton = NewDialogButton(
			"GoToSelectionOfAPickingJob", 
			NStr("vi = 'Chuyển 
			|đến chọn nhiệm vụ lấy ra';
			|ru = 'Перейти 
			|к выбору задания на отбор';
			|en = 'Go to
			|picking job selection'; fa = 'Go to
			|picking job selection';
			|it = 'Passare 
			|alla selezione del task di selezione';
			|pl = 'Przejść 
			|do wyboru zadania na wybór';
			|tr = 'Filtre için görev seçimine 
			|git'"), True);
		
	ElsIf JobType = "Location" Then
		
		GoButton = NewDialogButton(
			"GoToSelectionOfAPlacementJob", 
			NStr("vi = 'Chuyển 
			|đến chọn nhiệm vụ xếp vào';
			|ru = 'Перейти 
			|к выбору задания на размещение';
			|en = 'Go to
			|put-away task selection'; fa = 'Go to
			|put-away task selection';
			|it = 'Passare 
			|alla selezione del task di collocamento';
			|pl = 'Przejść 
			|do wyboru zadania na umieszczenie';
			|tr = 'Yerleştirme için görev seçimine 
			|git'"), True);
		
	ElsIf JobType = "Move" Then
		
		GoButton = NewDialogButton(
			"GoToSelectionOfATransferJob", 
			NStr("vi = 'Chuyển 
			|đến chọn nhiệm vụ điều chuyển';
			|ru = 'Перейти 
			|к выбору задания на перемещение';
			|en = 'Go to
			|transfer task selection'; fa = 'Go to
			|transfer task selection';
			|it = 'Passare 
			|alla selezione del task di spostamento';
			|pl = 'Przejść 
			|do wyboru zadania na przeniesienie';
			|tr = 'Transfer için görev seçimine 
			|git'"), True);
		
	ElsIf JobType = "Recalculate" Then
		
		GoButton = NewDialogButton(
			"GoToSelectionOfARecountJob", 
			NStr("vi = 'Chuyển 
			|đến chọn nhiệm vụ kiểm đếm';
			|ru = 'Перейти 
			|к выбору задания на пересчет';
			|en = 'Go to
			|physical count task selection'; fa = 'Go to
			|physical count task selection';
			|it = 'Passare 
			|alla selezione del task di ricalcolo';
			|pl = 'Przejść 
			|do wyboru zadania na przeliczenie';
			|tr = 'Yeniden sayım için görev seçimine 
			|git'"), True);
		
	ElsIf JobType = "Receiving" Then
		
		GoButton = NewDialogButton(
			"MainMenuAcceptance", 
			NStr("vi = 'Chuyển 
			|đến chọn nhiệm vụ tiếp nhận';
			|ru = 'Перейти 
			|к выбору задания на приемку';
			|en = 'Go to
			|goods receipt task selection'; fa = 'Go to
			|goods receipt task selection';
			|it = 'Passare 
			|alla selezione del task di accettazione';
			|pl = 'Przejść 
			|do wyboru zadania na odbiór';
			|tr = 'Kabul için görev seçimine 
			|git'"), True);
		
	ElsIf JobType = "PickingCheck" Then
		
		GoButton = NewDialogButton(
			"MainMenuSelectionCheck", 
			NStr("vi = 'Chuyển 
			|đến chọn nhiệm vụ kiểm tra lấy ra';
			|ru = 'Перейти 
			|к выбору задания на проверку отбора';
			|en = 'Go to
			|follow-up check selection'; fa = 'Go to
			|follow-up check selection';
			|it = 'Passare 
			|alla selezione del task di verifica della selezione';
			|pl = 'Przejść 
			|do wyboru zadania na weryfikację wyboru';
			|tr = 'Filtre kontrolü için görev seçimine 
			|git'"), True);
		
	Else
		
		GoButton = NewDialogButton(
			"GoToWarehouseOperationSelection", 
			NStr("vi = 'Chuyển 
			|đến chọn giao dịch';
			|ru = 'Перейти 
			|к выбору операции';
			|en = 'Go to
			|task selection'; fa = 'Go to
			|task selection';
			|it = 'Passare 
			|alla selezione dell''operazione';
			|pl = 'Przejść 
			|do wyboru czynności';
			|tr = 'İşlem seçimine 
			|git'"), True);
		
	EndIf;
	
	Buttons.Add(GoButton);
	
EndProcedure

// Sets the values of the mode parameters.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure InitializeModeParameters(Form)
	
	Parameters = Form.Parameters;
	WebServiceMode = Form.WebServiceMode;
	Form.ModeSettings = ModeSettings();
	
	If WebServiceMode Then
		Form.ModeSettings.NameOfTheWarehouse = Parameters.NameOfTheWarehouse;
		Form.ModeSettings.WareroomName = Parameters.WareroomName;
	EndIf;
	
	Form.ModeSettings.ProcessingProcedure_ = Form.WarehouseJobProcessingProcedure;
	
	Form.ModeSettings.ShippingZone = Catalogs.StorageBins.DefaultShippingZone(Form.Object.Warehouse, Form.Object.Premise);
	Form.ModeSettings.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Form.Object.Warehouse, Form.Object.Premise);
	
EndProcedure

// Sets the highlighting of the form element.
//
// Parameters:
//	ScreenResolution - EnumRef.ScreenResolutions
//	Item - FormButton - form element.
//
Procedure HighlightElement(ScreenResolution, Item)
	
	If (ScreenResolution = Enums.ScreenResolutions.Resolution240x320) Then
		BoldFont = New Font(,8, True);
	Else
		BoldFont = New Font(,9,True);
	EndIf;
	
	Item.BackColor = StyleColors.FileLockedByCurrentUser;
	Item.TextColor = WebColors.Snow;
	Item.Font = BoldFont;
	
EndProcedure

// Removes the highlight from the form element.
//
// Parameters:
//	Item - FormButton - form element.
//
Procedure RemoveElementIllumination(Item)
	
	AutoColor = New Color();
	AutoFont = New Font(,9);
	
	Item.BackColor = AutoColor;
	Item.TextColor = AutoColor;
	Item.Font = AutoFont;
	
EndProcedure

// Sets the illumination of scan elements.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetIlluminationOfScanningElements(Form)
	
	Items = Form.Items;
	ScanParameter = Form.ModeSettings.ScanParameter;
	
	RemoveElementIllumination(Items.ScanCell);
	RemoveElementIllumination(Items.ScanTheProduct);
	RemoveElementIllumination(Items.ScanSeries);
	
	If ScanParameter = "Cell" Then
		HighlightElement(Form.ScreenResolution, Items.ScanCell);
	ElsIf ScanParameter = "Products" Then
		HighlightElement(Form.ScreenResolution, Items.ScanTheProduct);
	ElsIf ScanParameter = "Series" Then
		HighlightElement(Form.ScreenResolution, Items.ScanSeries);
	EndIf;
	
EndProcedure

// Sets the availability of the button for entering the scanned quantity of products.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ScanToEnterTheNumber -FormButton - performs the opening pages of the input quantities.
//			** ScanNotShip -FormButton - opens the page for entering the quantity of unloaded goods.
//
Procedure SetQuantityInputAvailability(Form)
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = ModeSettings.SetOfProducts_;
	SelectionScanned = ModeSettings.SelectionScanned;
	ScanParameter = ModeSettings.ScanParameter;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	AvailabilityDoNotShip = False;
	AvailabilityOfQuantityInput = False;
	
	SeriesAreSpecified = SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus);
	SeriesAreSpecifiedForReference = SeriesAreSpecifiedForReference(CurrentScanningLine.BatchesIndicationStatus);
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If ThisIsSetOfGoods 
		Or JobType = "Receiving"
		Or JobType = "Recalculate" Then
		
		If JobType = "Receiving" Then
			
			If SeriesAreSpecified
				And SeriesAreSpecifiedForReference
				And SeriesIdentifiesItemInstance(CurrentScanningLine) Then
				
				AvailabilityOfQuantityInput = False;
				
			Else
				If ScanParameter = "Products" Then
					AvailabilityOfQuantityInput = ValueIsFilled(CurrentScanningLine.SKProducts);
				ElsIf ScanParameter = "Series" Then
					AvailabilityOfQuantityInput = ValueIsFilled(CurrentScanningLine.SkSeries);
				EndIf;
			EndIf;
			
		Else
			
			If ScanParameter = "Products" Then
				AvailabilityOfQuantityInput = ValueIsFilled(CurrentScanningLine.SKProducts);
			ElsIf ScanParameter = "Series" Then
				AvailabilityOfQuantityInput = ValueIsFilled(CurrentScanningLine.SkSeries);
			EndIf;
			
		EndIf;
		
	Else
		
		If JobType = "PickingCheck" Then
			
			ReferenceSeriesIsUnique = SeriesAreSpecifiedForReference
										And SeriesIdentifiesItemInstance(CurrentScanningLine);
			
			If Not SeriesAreSpecified Then
				AvailabilityOfQuantityInput = ValueIsFilled(CurrentScanningLine.SKProducts);
			Else
				If Not ReferenceSeriesIsUnique Then
					AvailabilityOfQuantityInput = ValueIsFilled(CurrentScanningLine.SkSeries);
				EndIf;
			EndIf;
			
			AvailabilityDoNotShip = AvailabilityOfQuantityInput;
			
		ElsIf JobType = "Location" Then
			If ThisIsProcessingOrderOfItemCell Then
				If ScanParameter = "Cell" Then
					AvailabilityOfQuantityInput = True;
				EndIf;
			Else
				If Not SeriesAreSpecified Then
					AvailabilityOfQuantityInput = ScannedItemMatchesItemOfScanLine(
						CurrentScanningLine);
				Else
					AvailabilityOfQuantityInput = ValueIsFilled(CurrentScanningLine.Series)
						And (CurrentScanningLine.Series = CurrentScanningLine.SkSeries);
				EndIf;
			EndIf;
		ElsIf JobType = "Move" Then
			If SelectionScanned And ThisIsProcessingOrderOfItemCell Then
				If ScanParameter = "Cell" Then
					AvailabilityOfQuantityInput = True;
				EndIf;
			Else
				If Not SeriesAreSpecified Then
					AvailabilityOfQuantityInput = ScannedItemMatchesItemOfScanLine(CurrentScanningLine);
				Else
					AvailabilityOfQuantityInput = (ValueIsFilled(CurrentScanningLine.BatchNumber)
						Or ValueIsFilled(CurrentScanningLine.ValidUntil_))
						And (CurrentScanningLine.BatchNumber = CurrentScanningLine.SKSeriesNumber
							And CurrentScanningLine.ValidUntil_ = CurrentScanningLine.SKIsGoodTo);
				EndIf;
			EndIf;
		Else
			If Not SeriesAreSpecified Then
				AvailabilityOfQuantityInput = ScannedItemMatchesItemOfScanLine(CurrentScanningLine);
			Else
				AvailabilityOfQuantityInput = (ValueIsFilled(CurrentScanningLine.BatchNumber)
					Or ValueIsFilled(CurrentScanningLine.ValidUntil_))
					And (CurrentScanningLine.BatchNumber = CurrentScanningLine.SKSeriesNumber
						And CurrentScanningLine.ValidUntil_ = CurrentScanningLine.SKIsGoodTo);
			EndIf;
		EndIf;
		
	EndIf;
	
	Items.ScanToEnterTheNumber.Enabled = AvailabilityOfQuantityInput;
	Items.ScanNotShip.Enabled  = AvailabilityDoNotShip;
	
EndProcedure

// Sets the availability of the scan item "Series".
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ScanSeries -FormButton - decorative element of the form.
//
Procedure SetSeriesAvailability(Form)
	
	SeriesAvailability = Form.UseItemsBatch;
	CurrentScanningLine = Form.CurrentScanningLine;
	Items = Form.Items;
	
	If Form.UseItemsBatch
		And ValueIsFilled(CurrentScanningLine.Products)
		And Not SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus)
			Or Not ValueIsFilled(CurrentScanningLine.Products) Then
		
		SeriesAvailability = False;
		
	EndIf;
	
	Items.ScanSeries.Enabled = SeriesAvailability;
	
EndProcedure

// Sets the availability of the "Destination" scan item.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ScanPurpose -FormButton - opens the page for specifying a separate item assignment.
//
Procedure SetDestinationAvailability(Form)
	
	Items = Form.Items;
	DestinationAvailability_ = True;
	JobType = Form.ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If Not Form.Object.UseOrderSupplyWithAssignment Then
		Return;
	EndIf;
	
	DestinationAvailability_ =
		Not JobType = "Filter"
		And (Not JobType = "Location"
			Or (Form.ModeSettings.SetOfProducts_))
		And Not JobType = "Move"
		And (Not DisplayScanItem(Form, "Cell")
			Or ThisIsProcessingOrderOfItemCell
			Or ValueIsFilled(CurrentScanningLine.SKCell))
		And ValueIsFilled(CurrentScanningLine.SKProducts)
		And (Not SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus)
			Or ValueIsFilled(CurrentScanningLine.SkSeries)
			Or ValueIsFilled(CurrentScanningLine.SKSeriesNumber)
			Or ValueIsFilled(CurrentScanningLine.SKIsGoodTo))
		And Not ThisIsTara(CurrentScanningLine);
	
	Items.ScanPurpose.Enabled = DestinationAvailability_;
	
EndProcedure

// Sets the title text of the cell scan element
// on the scan page.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ScanCell -FormButton - decorative element of the form.
//
Procedure SetCellTitle(Form)
	
	Items = Form.Items;
	WebServiceMode = Form.WebServiceMode;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	ScanParameter = Form.ModeSettings.ScanParameter;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	CellTitle = "";
	
	If JobType = "Receiving" Then
		Return;
	EndIf;
	
	If ThisIsSetOfGoods Then
		If ValueIsFilled(CurrentScanningLine.SKCell) Then
			
			CellTitle = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Ô hàng: %1';
																						|ru = 'Ячейка: %1';
																						|en = 'Storage bin: %1'; fa = 'Storage bin: %1';
																						|it = 'Cella: %1';
																						|pl = 'Komórka: %1';
																						|tr = 'Hücre: %1'"),
				?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.SKCell));
			
		Else
			CellTitle = NStr("vi = '<Khu vực nhập hàng (xuất hàng)>';
							|ru = '<Зона приемки (отгрузки)>';
							|en = '<Inbound/Outbound area>'; fa = '<Inbound/Outbound area>';
							|it = '<Inbound/Outbound area>';
							|pl = '<Strefa odbioru (wysyłki)>';
							|tr = '<Boşaltma alanı (yükleme)>'");
		EndIf;
	Else
		If JobType = "Location" Then
			
			If ThisIsProcessingOrderOfItemCell Then
				If ScanParameter = "Products"
					Or ScanParameter = "Series" Then
					
					CellTitle = NStr("vi = '<Ô hàng>';
									|ru = '<Ячейка>';
									|en = '<Storage bin>'; fa = '<محل نگهداری>';
									|it = '<cella>';
									|pl = '<komórka>';
									|tr = '<Hücre>'");
					
				EndIf;
			EndIf;
			
		ElsIf JobType = "Move" Then
			
			If ThisIsProcessingOrderOfItemCell Then
				If SelectionScanned Then
					If ScanParameter = "Products" 
						Or ScanParameter = "Series" Then
						
						CellTitle = NStr("vi = '<Ô hàng>';
										|ru = '<Ячейка>';
										|en = '<Storage bin>'; fa = '<محل نگهداری>';
										|it = '<cella>';
										|pl = '<komórka>';
										|tr = '<Hücre>'");
						
					EndIf;
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(CellTitle) Then
		
		CellTitle = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Ô hàng (%1 trong %2): %3';
																					|ru = 'Ячейка (%1 из %2): %3';
																					|en = 'Storage bin %3 (%1 out of %2)'; fa = 'Storage bin %3 (%1 out of %2)';
																					|it = 'Cella (%1 di %2): %3';
																					|pl = 'Komórka (%1 z %2): %3';
																					|tr = '<Hücre> (%2''dan %1): %3'"),
			CurrentScanningLine.CellNumber,
			CurrentScanningLine.NumberOfBins,
			?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
		
	EndIf;
	
	Items.ScanCell.Title = CellTitle;
	
EndProcedure

// Generates and sets the header value on the "Product" scanning element.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ScanTheProduct -FormButton - performs the opening pages of the output information about the product.
//
Procedure SetProductTitle(Form)
	
	Items = Form.Items;
	WebServiceMode = Form.WebServiceMode;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	CurrentScanningLine = Form.CurrentScanningLine;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	ScanParameter = Form.ModeSettings.ScanParameter;
	
	ThisIsUnknownBarcode = ThisIsUnknownBarcode(CurrentScanningLine);
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	ProductTitle_ = "";
	
	If ThisIsSetOfGoods Then
		
		If ValueIsFilled(CurrentScanningLine.Products)
			Or ValueIsFilled(CurrentScanningLine.PackingList) Then
			
			ProductTitle_ = NStr("vi = 'Đã thêm: [PackingList] [Products] [Characteristic]';
								|ru = 'Добавлен: [PackingList] [Products] [Characteristic]';
								|en = 'Item added: [PackingList] [Products] [Characteristic]'; fa = 'Item added: [PackingList] [Products] [Characteristic]';
								|it = 'Aggiunto: [PackingList] [Products] [Characteristic]';
								|pl = 'Dodano: [PackingList][Products][Characteristic]';
								|tr = 'Eklendi: [PackingList] [Products] [Characteristic]'");
			
		ElsIf ThisIsUnknownBarcode Then
			ProductTitle_ = NStr("vi = 'Đã thêm mã vạch: [Barcode]';
								|ru = 'Добавлен штрихкод: [Barcode]';
								|en = 'Barcode added: [Barcode]'; fa = 'Barcode added: [Barcode]';
								|it = 'Aggiunto il codice a barre: [Barcode]';
								|pl = 'Dodano kod kreskowy: [Barcode]';
								|tr = 'Barkod eklendi: [Barcode]'");
		ElsIf Form.UsePackingLists 
			And JobType = "Receiving" Then
			
			ProductTitle_ = NStr("vi = '<Hàng hóa / Phiếu đóng gói>';
								|ru = '<Товар / Упаковочный лист>';
								|en = '<Item/Packing list>'; fa = '<Item/Packing list>';
								|it = '<Merce / Distinta di imballaggio>';
								|pl = '<Towar / Lista pakowa>';
								|tr = '<Ürün / Ürün listesi>'");
			
		Else
			ProductTitle_ = NStr("vi = '<Hàng hóa>';
								|ru = '<Товар>';
								|en = '<Item>'; fa = '<قلم>';
								|it = '<merce>';
								|pl = '<towar>';
								|tr = '<Ürün>'");
		EndIf;
		
		ProductTitle_ = StringFunctionsClientServer.InsertParametersIntoString(ProductTitle_, CurrentScanningLine);
		
	ElsIf JobType = "Recalculate" Then
		
		If Not ValueIsFilled(CurrentScanningLine.Products) Then
			ProductTitle_ = NStr("vi = '<Hàng hóa>';
								|ru = '<Товар>';
								|en = '<Item>'; fa = '<قلم>';
								|it = '<merce>';
								|pl = '<towar>';
								|tr = '<Ürün>'");
		Else
			ProductTitle_ = NStr("vi = 'Đã quét: [Products] [Characteristic]';
								|ru = 'Отсканирован: [Products] [Characteristic]';
								|en = 'Item scanned: [Products] [Characteristic]'; fa = 'Item scanned: [Products] [Characteristic]';
								|it = 'Scansionato:  [Products] [Characteristic]';
								|pl = 'Zeskanowano: [Products] [Characteristic]';
								|tr = 'Tarandı: [Products] [Characteristic]'");
		EndIf;
		
		If WebServiceMode
			And ValueIsFilled(CurrentScanningLine.Products) Then
			
			ProductTitle_ = NStr("vi = 'Quét: [ItemName] [ItemVariantName]';
								|ru = 'Отсканирован: [ItemName] [ItemVariantName]';
								|en = 'Item scanned: [ItemName] [ItemVariantName]'; fa = 'Item scanned: [ItemName] [ItemVariantName]';
								|it = 'Scansionato: [ItemName] [ItemVariantName]';
								|pl = 'Zeskanowano: [ItemName] [ItemVariantName]';
								|tr = 'Tarandı: [ItemName] [ItemVariantName]'");
			
		EndIf;
		
		ProductTitle_ = StringFunctionsClientServer.InsertParametersIntoString(ProductTitle_, CurrentScanningLine);
		
	ElsIf JobType = "Filter" Then
		
		ProductTitle_ = StringFunctionsClientServer.InsertParametersIntoString(
			?(WebServiceMode,
				NStr("vi = 'Cần lấy ra ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): [ItemName] 
					|[ItemVariantName]';
					|ru = 'Взять ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): [ItemName] 
					|[ItemVariantName]';
					|en = 'Pick ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]): [ItemName]
					|[ItemVariantName]'; fa = 'Pick ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]): [ItemName]
					|[ItemVariantName]';
					|it = 'Prendere ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): [ItemName] 
					|[ItemVariantName]';
					|pl = 'Wziąć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): [ItemName] 
					| [ItemVariantName]';
					|tr = 'Al ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): [ItemName] 
					|[ItemVariantName]'"),
				NStr("vi = 'Lấy ([GoodsNumberInTheBin] từ [QuantityOfGoodsInABin]): [Products] [Characteristic]';
					|ru = 'Взять ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): [Products] [Characteristic]';
					|en = 'Pick ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]): [Products] [Characteristic]'; fa = 'Pick ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]): [Products] [Characteristic]';
					|it = 'Prendere ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): [Products] [Characteristic]';
					|pl = 'Wziąć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): [Products] [Characteristic]';
					|tr = 'Al ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): [Products] [Characteristic]'")),
			CurrentScanningLine);
		
	ElsIf JobType = "Location" Then
		
		If ThisIsProcessingOrderOfItemCell
			And (CurrentScanningLine = Undefined)
			Or Not ValueIsFilled(CurrentScanningLine.Products)
			Or TaskLineScanned(CurrentScanningLine, Form.ModeSettings)
			And Not ScanParameter = "Cell" Then
			
			ProductTitle_ = NStr("vi = '<Hàng hóa>';
								|ru = '<Товар>';
								|en = '<Item>'; fa = '<قلم>';
								|it = '<merce>';
								|pl = '<towar>';
								|tr = '<Ürün>'");
			
		Else
			
			ProductTitle_ = ?(WebServiceMode,
				NStr("vi = 'Cần xếp ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): 
					|[ItemName] [ItemVariantName]';
					|ru = 'Положить ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): 
					|[ItemName] [ItemVariantName]';
					|en = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
					|[ItemName] [ItemVariantName]'; fa = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
					|[ItemName] [ItemVariantName]';
					|it = 'Collocare ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): 
					|[ItemName] [ItemVariantName]';
					|pl = 'Położyć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): 
					| [ItemName] [ItemVariantName]';
					|tr = 'Koy ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): 
					|[ItemName] [ItemVariantName]'"),
				NStr("vi = 'Cần xếp ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): [Products] 
					|[Characteristic]';
					|ru = 'Положить ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): [Products] 
					|[Characteristic]';
					|en = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
					|[Products] [Characteristic]'; fa = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
					|[Products] [Characteristic]';
					|it = 'Collocare ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): [Products] 
					|[Characteristic]';
					|pl = 'Położyć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): [Products]
					|[Characteristic]';
					|tr = 'Koy ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): [Products] 
					|[Characteristic]'"));
			
		EndIf;
		
		ProductTitle_ = StringFunctionsClientServer.InsertParametersIntoString(ProductTitle_, CurrentScanningLine);
		
	ElsIf JobType = "Move" Then
		
		If Not SelectionScanned Then
			
			ProductTitle_ = ?(WebServiceMode,
				NStr("vi = 'Cần lấy ra ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): 
					|[ItemName] [ItemVariantName]';
					|ru = 'Взять ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): 
					|[ItemName] [ItemVariantName]';
					|en = 'Pick ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
					|[ItemName] [ItemVariantName]'; fa = 'Pick ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
					|[ItemName] [ItemVariantName]';
					|it = 'Prendere ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): 
					|[ItemName] [ItemVariantName]';
					|pl = 'Wziąć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): 
					|[ItemName][ItemVariantName]';
					|tr = 'Al ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): 
					|[ItemName] [ItemVariantName]'"),
				NStr("vi = 'Cần lấy ra ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): [Products] 
					|[Characteristic]';
					|ru = 'Взять ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): [Products] 
					|[Characteristic]';
					|en = 'Pick ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]): [Products]
					|[Characteristic]'; fa = 'Pick ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]): [Products]
					|[Characteristic]';
					|it = 'Prendere ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): [Products] 
					|[Characteristic]';
					|pl = 'Wziąć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): [Products]
					|[Characteristic]';
					|tr = 'Al ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): [Products] 
					|[Characteristic]'"));
			
		Else
			
			If ThisIsProcessingOrderOfItemCell Then
				If (CurrentScanningLine = Undefined)
					Or Not ValueIsFilled(CurrentScanningLine.Products) 
					Or TaskLineScanned(CurrentScanningLine, Form.ModeSettings)
					And Not ScanParameter = "Cell" Then
					
					ProductTitle_ = NStr("vi = '<Hàng hóa>';
										|ru = '<Товар>';
										|en = '<Item>'; fa = '<قلم>';
										|it = '<merce>';
										|pl = '<towar>';
										|tr = '<Ürün>'");
					
				Else
					
					ProductTitle_ = ?(WebServiceMode,
						NStr("vi = 'Cần xếp ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): 
							|[ItemName] [ItemVariantName]';
							|ru = 'Положить ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): 
							|[ItemName] [ItemVariantName]';
							|en = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
							|[ItemName] [ItemVariantName]'; fa = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
							|[ItemName] [ItemVariantName]';
							|it = 'Collocare ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): 
							|[ItemName] [ItemVariantName]';
							|pl = 'Położyć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): 
							| [ItemName] [ItemVariantName]';
							|tr = 'Koy ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): 
							|[ItemName] [ItemVariantName]'"),
						NStr("vi = 'Cần xếp ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): [Products] 
							|[Characteristic]';
							|ru = 'Положить ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): [Products] 
							|[Characteristic]';
							|en = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
							|[Products] [Characteristic]'; fa = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
							|[Products] [Characteristic]';
							|it = 'Collocare ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): [Products] 
							|[Characteristic]';
							|pl = 'Położyć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): [Products]
							|[Characteristic]';
							|tr = 'Koy ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): [Products] 
							|[Characteristic]'"));
					
				EndIf;
			Else
				
				ProductTitle_ = ?(WebServiceMode,
					NStr("vi = 'Cần xếp ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): 
						|[ItemName] [ItemVariantName]';
						|ru = 'Положить ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): 
						|[ItemName] [ItemVariantName]';
						|en = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
						|[ItemName] [ItemVariantName]'; fa = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
						|[ItemName] [ItemVariantName]';
						|it = 'Collocare ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): 
						|[ItemName] [ItemVariantName]';
						|pl = 'Położyć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): 
						| [ItemName] [ItemVariantName]';
						|tr = 'Koy ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): 
						|[ItemName] [ItemVariantName]'"),
					NStr("vi = 'Cần xếp ([GoodsNumberInTheBin] trong số [QuantityOfGoodsInABin]): [Products] 
						|[Characteristic]';
						|ru = 'Положить ([GoodsNumberInTheBin] из [QuantityOfGoodsInABin]): [Products] 
						|[Characteristic]';
						|en = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
						|[Products] [Characteristic]'; fa = 'Put ([GoodsNumberInTheBin] out of [QuantityOfGoodsInABin]):
						|[Products] [Characteristic]';
						|it = 'Collocare ([GoodsNumberInTheBin] di [QuantityOfGoodsInABin]): [Products] 
						|[Characteristic]';
						|pl = 'Położyć ([GoodsNumberInTheBin] z [QuantityOfGoodsInABin]): [Products]
						|[Characteristic]';
						|tr = 'Koy ([QuantityOfGoodsInABin]''dan [GoodsNumberInTheBin]): [Products] 
						|[Characteristic]'"));
				
			EndIf
			
		EndIf;
		
		ProductTitle_ = StringFunctionsClientServer.InsertParametersIntoString(ProductTitle_, CurrentScanningLine);
		
	ElsIf JobType = "Receiving" Then
		
		ProductTitle_ = StringFunctionsClientServer.InsertParametersIntoString(
			?(WebServiceMode,
				NStr("vi = 'Hàng hóa: [ItemName] [ItemVariantName]';
					|ru = 'Товар: [ItemName] [ItemVariantName]';
					|en = 'Item: [ItemName] [ItemVariantName]'; fa = 'Item: [ItemName] [ItemVariantName]';
					|it = 'Merce: [ItemName] [ItemVariantName]';
					|pl = 'Towar: [ItemName][ItemVariantName]';
					|tr = 'Ürün: [ItemName] [ItemVariantName]'"),
				NStr("vi = 'Hàng hóa: [Products] [Characteristic]';
					|ru = 'Товар: [Products] [Characteristic]';
					|en = 'Item: [Products] [Characteristic]'; fa = 'Item: [Products] [Characteristic]';
					|it = 'Merce: [Products] [Characteristic]';
					|pl = 'Towar: [Products] [Characteristic]';
					|tr = 'Ürün: [Products] [Characteristic]'")),
			CurrentScanningLine);
		
	ElsIf JobType = "PickingCheck" Then
		
		ProductTitle_ = StringFunctionsClientServer.InsertParametersIntoString(
		?(WebServiceMode,
			NStr("vi = 'Hàng hóa: [ItemName] [ItemVariantName]';
				|ru = 'Товар: [ItemName] [ItemVariantName]';
				|en = 'Item: [ItemName] [ItemVariantName]'; fa = 'Item: [ItemName] [ItemVariantName]';
				|it = 'Merce: [ItemName] [ItemVariantName]';
				|pl = 'Towar: [ItemName][ItemVariantName]';
				|tr = 'Ürün: [ItemName] [ItemVariantName]'"),
			NStr("vi = 'Hàng hóa: [Products] [Characteristic]';
				|ru = 'Товар: [Products] [Characteristic]';
				|en = 'Item: [Products] [Characteristic]'; fa = 'Item: [Products] [Characteristic]';
				|it = 'Merce: [Products] [Characteristic]';
				|pl = 'Towar: [Products] [Characteristic]';
				|tr = 'Ürün: [Products] [Characteristic]'")),
		CurrentScanningLine);
		
	EndIf;
	
	Items.ScanTheProduct.Title = ProductTitle_;
	
EndProcedure

// Generates and sets the title value on the scan element " Series" 
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ScanSeries -FormButton - decorative element of the form.
//
Procedure SetSeriesTitle(Form)
	
	Items = Form.Items;
	WebServiceMode = Form.WebServiceMode;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	SelectionScanned = ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	ScanParameter = Form.ModeSettings.ScanParameter;
	UseItemsBatch = Form.UseItemsBatch;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	SeriesAreSpecified = SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus);
	SeriesAreSpecifiedForReference = SeriesAreSpecifiedForReference(CurrentScanningLine.BatchesIndicationStatus);
	
	If Not UseItemsBatch
		Or Not SeriesAreSpecified Then
		
		Items.ScanSeries.Title = NStr("vi = '<Chưa chỉ ra sê-ri>';
										|ru = '<Серия не указывается>';
										|en = '<Batch not specified>'; fa = '<Batch not specified>';
										|it = '<Serie non è indicata>';
										|pl = '<seria nie jest określana>';
										|tr = '<Parti belirtilmemektedir>'");
		Return;
		
	EndIf;
	
	If Not ValueIsFilled(CurrentScanningLine.Products) Then
		Items.ScanSeries.Title = NStr("vi = '<Sê-ri>';
										|ru = '<Серия>';
										|en = '<Batch>'; fa = '<بچ>';
										|it = '<serie>';
										|pl = '<Batch>';
										|tr = '<Parti>'");
		Return;
	EndIf;
	
	If ThisIsSetOfGoods Then
		If ValueIsFilled(CurrentScanningLine.Series) Then
			SeriesTitle = NStr("vi = 'Sê-ri: %1';
								|ru = 'Серия: %1';
								|en = 'Batch: %1'; fa = 'Batch: %1';
								|it = 'Serie:%1';
								|pl = 'Seria: %1';
								|tr = 'Parti: %1'");
		EndIf;
	Else
		If JobType = "Recalculate" Then
			
			If ScanParameter = "Series" Then
				If ValueIsFilled(CurrentScanningLine.Series) Then
					SeriesTitle = NStr("vi = 'Sê-ri: %1';
										|ru = 'Серия: %1';
										|en = 'Batch: %1'; fa = 'Batch: %1';
										|it = 'Serie:%1';
										|pl = 'Seria: %1';
										|tr = 'Parti: %1'");
				EndIf;
			EndIf;
			
		ElsIf JobType = "PickingCheck" Then
			
			SeriesTitle = NStr("vi = '<Sê-ri>';
								|ru = '<Серия>';
								|en = '<Batch>'; fa = '<بچ>';
								|it = '<serie>';
								|pl = '<seria>';
								|tr = '<Parti>'");
			
			If SeriesAreSpecifiedForReference Then
				If ValueIsFilled(CurrentScanningLine.Series) Then
					SeriesTitle = NStr("vi = 'Sê-ri: %1';
										|ru = 'Серия: %1';
										|en = 'Batch: %1'; fa = 'Batch: %1';
										|it = 'Serie:%1';
										|pl = 'Seria: %1';
										|tr = 'Parti: %1'");
				EndIf;
			ElsIf SeriesAreSpecified Then
				SeriesTitle = NStr("vi = 'Sê-ri: %1';
									|ru = 'Серия: %1';
									|en = 'Batch: %1'; fa = 'Batch: %1';
									|it = 'Serie:%1';
									|pl = 'Seria: %1';
									|tr = 'Parti: %1'");
			EndIf;
			
		ElsIf JobType = "Location" Then
			
			If ValueIsFilled(CurrentScanningLine.Series) Then
				If ThisIsProcessingOrderOfItemCell Then
					If ValueIsFilled(CurrentScanningLine.SkSeries) Then
						SeriesTitle = NStr("vi = 'Sê-ri: %1';
											|ru = 'Серия: %1';
											|en = 'Batch: %1'; fa = 'Batch: %1';
											|it = 'Serie:%1';
											|pl = 'Seria: %1';
											|tr = 'Parti: %1'");
					Else
						 SeriesTitle = NStr("vi = '<Sê-ri>';
											|ru = '<Серия>';
											|en = '<Batch>'; fa = '<بچ>';
											|it = '<serie>';
											|pl = '<seria>';
											|tr = '<Parti>'");
					EndIf;
				Else
					SeriesTitle = NStr("vi = 'Sê-ri: %1';
										|ru = 'Серия: %1';
										|en = 'Batch: %1'; fa = 'Batch: %1';
										|it = 'Serie:%1';
										|pl = 'Seria: %1';
										|tr = 'Parti: %1'");
				EndIf;
			EndIf;
			
		ElsIf JobType = "Move" Then
			
			If ValueIsFilled(CurrentScanningLine.BatchNumber)
				Or ValueIsFilled(CurrentScanningLine.ValidUntil_) Then
				
				If SelectionScanned 
					And ThisIsProcessingOrderOfItemCell Then
					
					If ValueIsFilled(CurrentScanningLine.SKSeriesNumber)
						Or ValueIsFilled(CurrentScanningLine.SKIsGoodTo) Then
						
						SeriesTitle = NStr("vi = 'Sê-ri: %1';
											|ru = 'Серия: %1';
											|en = 'Batch: %1'; fa = 'Batch: %1';
											|it = 'Serie:%1';
											|pl = 'Seria: %1';
											|tr = 'Parti: %1'");
						
					EndIf;
					
				Else
					SeriesTitle = NStr("vi = 'Sê-ri: %1';
										|ru = 'Серия: %1';
										|en = 'Batch: %1'; fa = 'Batch: %1';
										|it = 'Serie:%1';
										|pl = 'Seria: %1';
										|tr = 'Parti: %1'");
				EndIf;
				
			EndIf;
			
		Else
			If ValueIsFilled(CurrentScanningLine.BatchNumber)
				Or ValueIsFilled(CurrentScanningLine.ValidUntil_) Then
				
				SeriesTitle = NStr("vi = 'Sê-ri: %1';
									|ru = 'Серия: %1';
									|en = 'Batch: %1'; fa = 'Batch: %1';
									|it = 'Serie:%1';
									|pl = 'Seria: %1';
									|tr = 'Parti: %1'");
				
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(SeriesTitle) Then
		SeriesTitle = NStr("vi = '<Sê-ri>';
							|ru = '<Серия>';
							|en = '<Batch>'; fa = '<بچ>';
							|it = '<serie>';
							|pl = '<seria>';
							|tr = '<Parti>'");
	EndIf;
	
	If JobType = "Filter"
		Or JobType = "Move" Then
		
		BatchPresentation = SetSeriesPresentation(CurrentScanningLine);
		
		SeriesTitle = StringFunctionsClientServer.SubstituteParametersToString(SeriesTitle,
			BatchPresentation);
		
	Else
		If ThisIsSetOfGoods Then
			SeriesTitle = StringFunctionsClientServer.SubstituteParametersToString(SeriesTitle, CurrentScanningLine.Series);
		Else
			CurrentScanningLine.BatchName = SetSeriesPresentation(CurrentScanningLine);
			
			SeriesTitle = StringFunctionsClientServer.SubstituteParametersToString(SeriesTitle,
				?(WebServiceMode, CurrentScanningLine.BatchName, CurrentScanningLine.Series));
		EndIf;
	EndIf;
	
	Items.ScanSeries.Title = SeriesTitle;
	
EndProcedure

// Generates and sets the header value on the scan item "do not ship Quantity".
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ScanNotShip -FormButton - opens the page for entering the quantity of unloaded goods.
//
Procedure SetQuantityHeaderDoNotShip(Form)
	
	Items = Form.Items;
	JobType = Form.ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	Items.ScanNotShip.Title = "";
	
	If Not (JobType = "PickingCheck") Then
		Return;
	EndIf;
	
	Items.ScanNotShip.Title = CurrentScanningLine.NumberOfPackagesDoNotShip;
	
EndProcedure

// Generates and sets the header value on the scan element "Quantity in document".
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** LabelQuantityInTheDocument -FormField - reflects the number of items in the warehouse task.
//
Procedure SetQuantityHeaderInDocument(Form)
	
	Items = Form.Items;
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	SeriesAreSpecified = SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus);
	
	Items.LabelQuantityInTheDocument.Title = "<>";
	
	If JobType = "Location" Then
		If Not ThisIsSetOfGoods
			And ThisIsProcessingOrderOfItemCell Then
			
			If SeriesAreSpecified Then
				If ValueIsFilled(CurrentScanningLine.SkSeries) Then
					Items.LabelQuantityInTheDocument.Title = CurrentScanningLine.NumberOfPackagesInDocument;
				EndIf;
			EndIf;
			
		Else
			Items.LabelQuantityInTheDocument.Title = CurrentScanningLine.NumberOfPackagesInDocument;
		EndIf;
	ElsIf JobType = "PickingCheck" Then
		Items.LabelQuantityInTheDocument.Title = CurrentScanningLine.NumberOfPackages;
	Else
		Items.LabelQuantityInTheDocument.Title = CurrentScanningLine.NumberOfPackagesInDocument;
	EndIf;
	
EndProcedure

// Generates and sets the header value on the scan item "Quantity".
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** TheInscriptionToTake -FormField - reflects the quantity of the product to be selected from the storage cell.
//			** TheInscriptionWasTaken -FormField - reflects the quantity of the selected item from the storage cell.
//			** LabelPackaging -FormField - reflects the name of the product packaging.
//			** LabelNumberOfPackages -FormField - reflects the number of packages of the product in the warehouse task.
//			** ScanToEnterTheNumber -FormButton - performs the opening pages set the number of goods.
//
Procedure SetQuantityHeader(Form)
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsAPackingList = ThisIsAPackingList(CurrentScanningLine);
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	// Clear all headers.
	Items.TheInscriptionToTake.Title = "";
	Items.TheInscriptionWasTaken.Title = "";
	Items.LabelPackaging.Title = "";
	Items.LabelNumberOfPackages.Title = "";
	Items.ScanToEnterTheNumber.Title = "";
	
	If ValueIsFilled(CurrentScanningLine.Package) Then
		Items.LabelPackaging.Title = ?(Form.WebServiceMode, CurrentScanningLine.PackageName,
			CurrentScanningLine.Package);
	ElsIf ThisIsAPackingList Then
		Items.LabelPackaging.Title = NStr("vi = 'vị trí';
											|ru = 'место';
											|en = 'place'; fa = 'place';
											|it = 'luogo';
											|pl = 'place';
											|tr = 'yer'");
	Else
		Items.LabelPackaging.Title = ?(Form.WebServiceMode, CurrentScanningLine.UnitOfMeasureDescription,
			CurrentScanningLine.UnitOfMeasure);
	EndIf;
	
	If ThisIsSetOfGoods Then
		
		If Form.ScreenResolution = Enums.ScreenResolutions.Resolution240x320 Then
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Thêm:';
														|ru = 'Доб.:';
														|en = 'Added:'; fa = 'Added:';
														|it = 'Agg.:';
														|pl = 'Added:';
														|tr = 'Ek.:'");
		Else
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Đã thêm:';
														|ru = 'Добавлено:';
														|en = 'Items added:'; fa = 'Items added:';
														|it = 'Aggiunto:';
														|pl = 'Items added:';
														|tr = 'Eklendi:'");
		EndIf;
		
		Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagingsScanned;
		
	ElsIf JobType = "Recalculate" Then
		
		If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Quét:';
														|ru = 'Отск.:';
														|en = 'Scanned:'; fa = 'Scanned:';
														|it = 'Scansionato:';
														|pl = 'Scanned:';
														|tr = 'Tarandı.:'");
		Else
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Đã quét:';
														|ru = 'Отсканировано:';
														|en = 'Items scanned:'; fa = 'Items scanned:';
														|it = 'Scansionato:';
														|pl = 'Items scanned:';
														|tr = 'Tarandı:'");
		EndIf;
		Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagingsScanned;
		
	ElsIf JobType = "Filter" Then
		
		Items.TheInscriptionToTake.Title = NStr("vi = 'Lấy:';
												|ru = 'Взять:';
												|en = 'Pick item:'; fa = 'Pick item:';
												|it = 'Prendere';
												|pl = 'Pick item:';
												|tr = 'Al:'");
		Items.TheInscriptionWasTaken.Title = NStr("vi = 'Đã lấy:';
													|ru = 'Взяли:';
													|en = 'Items picked:'; fa = 'Items picked:';
													|it = 'Presi:';
													|pl = 'Items picked:';
													|tr = 'Alındı:'");
		
		Items.LabelNumberOfPackages.Title = CurrentScanningLine.NumberOfPackages;
		Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagingsScanned;
		
	ElsIf JobType = "Location" Then
		
		If ThisIsProcessingOrderOfItemCell Then
			Items.TheInscriptionToTake.Title = NStr("vi = 'Còn lại:';
													|ru = 'Осталось:';
													|en = 'Remaining:'; fa = 'Remaining:';
													|it = 'Rimasto:';
													|pl = 'Remaining:';
													|tr = 'Kaldı:'");
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Kho bãi:';
														|ru = 'Кладу:';
														|en = 'Put:'; fa = 'Put:';
														|it = 'Colloco:';
														|pl = 'Put:';
														|tr = 'Ambara:'");
			
			Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagesToPut;
			Items.LabelNumberOfPackages.Title = CurrentScanningLine.NumberOfPackagesInDocument - 
				CurrentScanningLine.NumberOfPackagesPut - CurrentScanningLine.NumberOfPackagesToPut;
		Else
			Items.TheInscriptionToTake.Title = NStr("vi = 'Đặt:';
													|ru = 'Положить:';
													|en = 'Put item:'; fa = 'Put item:';
													|it = 'Collocare:';
													|pl = 'Put item:';
													|tr = 'Koy:'");
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Đã đặt:';
														|ru = 'Положили:';
														|en = 'Items put:'; fa = 'Items put:';
														|it = 'Sono stati collocati:';
														|pl = 'Items put:';
														|tr = 'Koyuldu:'");
			
			Items.LabelNumberOfPackages.Title = CurrentScanningLine.NumberOfPackages;
			Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagingsScanned;
		EndIf;
		
	ElsIf JobType = "Move" Then
		
		If Not SelectionScanned Then
			Items.TheInscriptionToTake.Title = NStr("vi = 'Lấy:';
													|ru = 'Взять:';
													|en = 'Pick item:'; fa = 'Pick item:';
													|it = 'Prendere';
													|pl = 'Pick item:';
													|tr = 'Al:'");
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Đã lấy:';
														|ru = 'Взяли:';
														|en = 'Items picked:'; fa = 'Items picked:';
														|it = 'Presi:';
														|pl = 'Items picked:';
														|tr = 'Alındı:'");
			
			Items.LabelNumberOfPackages.Title = CurrentScanningLine.NumberOfPackages;
			Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagingsScanned;
		Else
			If ThisIsProcessingOrderOfItemCell Then
				
				Items.TheInscriptionToTake.Title = NStr("vi = 'Còn lại:';
														|ru = 'Осталось:';
														|en = 'Remaining:'; fa = 'Remaining:';
														|it = 'Rimasto:';
														|pl = 'Remaining:';
														|tr = 'Kaldı:'");
				Items.TheInscriptionWasTaken.Title = NStr("vi = 'Kho bãi:';
															|ru = 'Кладу:';
															|en = 'Put:'; fa = 'Put:';
															|it = 'Colloco:';
															|pl = 'Put:';
															|tr = 'Ambara:'");
				Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagesToPut;
				
				Items.LabelNumberOfPackages.Title = CurrentScanningLine.NumberOfPackages - 
					CurrentScanningLine.NumberOfPackagesPut - CurrentScanningLine.NumberOfPackagesToPut;
			Else
				Items.TheInscriptionToTake.Title = NStr("vi = 'Đặt:';
														|ru = 'Положить:';
														|en = 'Put item:'; fa = 'Put item:';
														|it = 'Collocare:';
														|pl = 'Put item:';
														|tr = 'Koy:'");
				Items.TheInscriptionWasTaken.Title = NStr("vi = 'Đã đặt:';
															|ru = 'Положили:';
															|en = 'Items put:'; fa = 'Items put:';
															|it = 'Sono stati collocati:';
															|pl = 'Items put:';
															|tr = 'Koyuldu:'");
				
				Items.LabelNumberOfPackages.Title = CurrentScanningLine.NumberOfPackages;
				Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagingsScanned;
			EndIf;
		EndIf;
		
	ElsIf JobType = "PickingCheck" Then
		
		If Form.ScreenResolution = Enums.ScreenResolutions.Resolution240x320 Then
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Có sẵn:';
														|ru = 'В налич.:';
														|en = 'In st-k:'; fa = 'In st-k:';
														|it = 'Disponibili:';
														|pl = 'Dostępne:';
														|tr = 'Stokta.:'");
		Else
			Items.TheInscriptionWasTaken.Title = NStr("vi = 'Trong kho:';
														|ru = 'В наличии:';
														|en = 'In stock:'; fa = 'In stock:';
														|it = 'Disponibili:';
														|pl = 'Dostępne:';
														|tr = 'Stokta:'");
		EndIf;
		Items.ScanToEnterTheNumber.Title = CurrentScanningLine.NumberOfPackagingsScanned;
		
	Else
		Items.TheInscriptionToTake.Title = NStr("vi = 'Lấy:';
												|ru = 'Взять:';
												|en = 'Pick item:'; fa = 'Pick item:';
												|it = 'Prendere';
												|pl = 'Pick item:';
												|tr = 'Al:'");
		Items.LabelNumberOfPackages.Title = CurrentScanningLine.NumberOfPackages;
	EndIf;
	
EndProcedure

// Generates and sets the title value on the scan element " Series" 
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ScanPurpose -FormButton - opens the page for specifying a separate item assignment.
//
Procedure SetDestinationHeader(Form)
	
	If Not Form.Object.UseOrderSupplyWithAssignment Then
		Return;
	EndIf;
	
	WebServiceMode = Form.WebServiceMode;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	DestinationHeader = NStr("vi = '<Mục đích>';
							|ru = '<Назначение>';
							|en = '<Assignment>'; fa = '<تخصیص>';
							|it = '<assegnazione>';
							|pl = '<Przeznaczenie>';
							|tr = '<Atama>'");
	
	If ValueIsFilled(CurrentScanningLine.Products) Then
		If ValueIsFilled(CurrentScanningLine.Purpose) Then
			DestinationHeader = NStr("vi = '%1';
									|ru = '%1';
									|en = '%1'; fa = '%1';
									|it = '%1';
									|pl = '%1';
									|tr = '%1'");
		Else
			DestinationHeader = NStr("vi = '<không mục đích>';
									|ru = '<без назначения>';
									|en = '<No assignment>'; fa = '<No assignment>';
									|it = '<senza assegnazione>';
									|pl = '<bez przeznaczenia>';
									|tr = '<atamasız>'");
		EndIf;
	EndIf;
	
	DestinationHeader = StringFunctionsClientServer.SubstituteParametersToString(DestinationHeader,
		?(WebServiceMode, CurrentScanningLine.PurposeDescription, CurrentScanningLine.Purpose));
	
	Form.Items.ScanPurpose.Title = DestinationHeader;
	
EndProcedure

// Sets the color of the scan elements.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetColorsOfScanItems(Form)
	
	Form.Items.ScanToEnterTheNumber.TextColor = StyleColors.ButtonTextColor;
	
EndProcedure

// Adds command buttons to the user's dialog message page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Button - Structure - the parameters button.
//
Procedure AddMessageDialogButton(Form, Button)
	
	If Button = Undefined Then
		Return;
	EndIf;
	
	FrameSelectionColor = StyleColors.FormTextColor;
	TagName = "Button" + Button.CommandName; 
	
	NewButton = Form.Items.Add(
		TagName, 
		Type("FormButton"), 
		Form.Items.ActionTeamGroup);
	
	NewButton.Type = FormButtonType.UsualButton;
	
	If Form.ScreenResolution = Enums.ScreenResolutions.Resolution240x320 Then
		NewButton.Width = 20;
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution320x320 Then
		NewButton.Width = 25;
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
		NewButton.Width = 44;
	EndIf;
	
	NewButton.Height = 2;
	NewButton.AutoMaxHeight = True;
	
	NewButton.Title = Button.Presentation;
	NewButton.CommandName = Button.CommandName;
	
	If Button.Select_ Then
		NewButton.Font = New Font(Form.Items[TagName].Font, , , True);
		NewButton.BorderColor = FrameSelectionColor;
	EndIf;
	
EndProcedure

// Retrieves the values of hint elements for the user. Depending on the task type, sets
// the values of the hint elements to the appropriate case.
//
// Parameters:
//	JobType - String - job type,
//	SelectionScanned - Boolean - indicates whether the selection scan is completed when moving,
//	TaskTypePresentation - Undefined - variable that the task type is written to,
//	ExecutionType - Undefined - variable that the execution type is written to,
//	ActionType - Undefined - the variable that the action type is written to.
//
Procedure GetValuesOfMessageElementsToUser(JobType, SelectionScanned, 
	TaskTypePresentation = "", ExecutionType = "", ActionType = "")
	
	If JobType = "Filter" Then
		
		TaskTypePresentation = Lower(JobType);
		
		ExecutionType = NStr("vi = 'lọc';
							|ru = 'отбора';
							|en = 'inventory picking'; fa = 'inventory picking';
							|it = 'della selezione';
							|pl = 'filtru';
							|tr = 'filtre'");
		ActionType   = NStr("vi = 'lọc';
							|ru = 'отбор';
							|en = 'inventory picking'; fa = 'inventory picking';
							|it = 'selezione';
							|pl = 'filtr';
							|tr = 'filtre'");
		
	ElsIf JobType = "Location" Then
		
		TaskTypePresentation = Lower(JobType);
		
		ExecutionType = NStr("vi = 'sắp xếp';
							|ru = 'размещения';
							|en = 'inventory put-away'; fa = 'inventory put-away';
							|it = 'di collocamento';
							|pl = 'rozmieszczanie';
							|tr = 'yerleştirme'");
		ActionType   = NStr("vi = 'sắp xếp';
							|ru = 'размещение';
							|en = 'inventory put-away'; fa = 'inventory put-away';
							|it = 'collocamento';
							|pl = 'lokalizacja';
							|tr = 'Yerleşim'");
		
	ElsIf JobType = "Move" Then
		
		TaskTypePresentation = Lower(JobType);
		
		If SelectionScanned Then
			ExecutionType = NStr("vi = 'lọc';
								|ru = 'отбора';
								|en = 'inventory picking'; fa = 'inventory picking';
								|it = 'della selezione';
								|pl = 'filtru';
								|tr = 'filtre'");
			ActionType   = NStr("vi = 'lọc';
								|ru = 'отбор';
								|en = 'inventory picking'; fa = 'inventory picking';
								|it = 'selezione';
								|pl = 'filtr';
								|tr = 'filtre'");
		Else
			ExecutionType = NStr("vi = 'sắp xếp';
								|ru = 'размещения';
								|en = 'inventory put-away'; fa = 'inventory put-away';
								|it = 'di collocamento';
								|pl = 'rozmieszczanie';
								|tr = 'yerleştirme'");
			ActionType = NStr("vi = 'sắp xếp';
								|ru = 'размещение';
								|en = 'inventory put-away'; fa = 'inventory put-away';
								|it = 'collocamento';
								|pl = 'lokalizacja';
								|tr = 'Yerleşim'");
		EndIf;
		
	ElsIf JobType = "Recalculate" Then
		
		TaskTypePresentation = Lower(JobType);
		
		ExecutionType = NStr("vi = 'kiểm đếm';
							|ru = 'пересчета';
							|en = 'inventory physical count'; fa = 'inventory physical count';
							|it = 'di ricalcolo';
							|pl = 'przeliczania';
							|tr = 'yeniden hesaplama'");
		ActionType = NStr("vi = 'kiểm đếm';
							|ru = 'пересчет';
							|en = 'inventory physical count'; fa = 'inventory physical count';
							|it = 'ricalcolo';
							|pl = 'przeliczenie';
							|tr = 'yeniden hesaplama'");
		
	ElsIf JobType = "Receiving" Then
		
		TaskTypePresentation = NStr("vi = 'nhập hàng';
									|ru = 'приемку';
									|en = 'goods receipt'; fa = 'goods receipt';
									|it = 'accettazione';
									|pl = 'odbiór';
									|tr = 'kabul'");
		
		ExecutionType = NStr("vi = 'nhập hàng';
							|ru = 'приемки';
							|en = 'goods receipt'; fa = 'goods receipt';
							|it = 'di accettazione';
							|pl = 'odbiory';
							|tr = 'kabuller'");
		ActionType = NStr("vi = 'nhập hàng';
							|ru = 'приемку';
							|en = 'goods receipt'; fa = 'goods receipt';
							|it = 'accettazione';
							|pl = 'odbiór';
							|tr = 'kabul'");
		
	ElsIf JobType = "PickingCheck" Then
		
		TaskTypePresentation = NStr("vi = 'kiểm tra việc lấy ra';
									|ru = 'проверки отбора';
									|en = 'follow-up check'; fa = 'follow-up check';
									|it = 'di verifica della selezione';
									|pl = 'weryfikacje wyboru';
									|tr = 'filtre kontrolü'");
		
		ExecutionType = NStr("vi = 'kiểm tra việc lấy ra';
							|ru = 'проверки отбора';
							|en = 'follow-up check'; fa = 'follow-up check';
							|it = 'di verifica della selezione';
							|pl = 'weryfikacje wyboru';
							|tr = 'filtre kontrolü'");
		ActionType = NStr("vi = 'kiểm tra việc lấy ra';
							|ru = 'проверку отбора';
							|en = 'follow-up check'; fa = 'follow-up check';
							|it = 'verifica della selezione';
							|pl = 'weryfikację wyboru';
							|tr = 'filtre kontrolü'");
		
	EndIf;
	
EndProcedure

// Returns the structure - parameters of the command with the assigned hotkey.
//
// Parameters:
//	Hotkey - Key - "hotkey.
//	CommandName - String - command name.
//	TagName - String - name of the element that belongs to the command.
//
// Returns:
//	Structure - Command parameters that contain the following fields:
//		* Shortcut - Shortcut - the combination of clones assigned to the team.
//		* CommandName - String - command name.
//		* TagName - String - name of the element that is linked to the command.
//
Function CommandParameters(Hotkey, CommandName, TagName = "")
	
	ParametersStructure = New Structure("Shortcut, CommandName, TagName");
	
	ParametersStructure.Shortcut = New Shortcut(Hotkey);
	ParametersStructure.CommandName = CommandName;
	ParametersStructure.TagName = ?(ValueIsFilled(TagName), TagName, CommandName);
	
	Return ParametersStructure;
	
EndFunction

// Returns an array of the names of the teams for which you want to install hot keys.
// The names of the commands are arranged in their order.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	PageName - String - page name.
//	DeleteKeys - Boolean
//
// Returns:
//	Array of See CommandParameters - array of command parameter structures.
//
Function CommandParametersOnFormPage(Form, PageName, DeleteKeys = False)
	
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	ArrayOfCommands = New Array;
	
	If PageName = "OperationSelectionPage" Then
		
		ArrayOfCommands.Add(CommandParameters(Key._0, "MainMenuAcceptance"));
		ArrayOfCommands.Add(CommandParameters(Key._1, "MainMenuPlacement"));
		ArrayOfCommands.Add(CommandParameters(Key._2, "MainMenuSelection"));
		ArrayOfCommands.Add(CommandParameters(Key._3, "MainMenuRecalculate"));
		ArrayOfCommands.Add(CommandParameters(Key._4, "CreateANewWarehouseTask"));
		ArrayOfCommands.Add(CommandParameters(Key._5, "MainMenuSelectionCheck"));
		ArrayOfCommands.Add(CommandParameters(Key._6, "MainMenuMove"));
		ArrayOfCommands.Add(CommandParameters(Key._7, "MainMenuInformation"));
		ArrayOfCommands.Add(CommandParameters(Key._8, "MainMenuUpdate"));
		ArrayOfCommands.Add(CommandParameters(Key._9, "MainMenuMarkCellToRecalculate"));
		
	ElsIf PageName = "PageJobSelection" Then
		
		ArrayOfCommands.Add(CommandParameters(Key._0, "SelectTasks"));
		ArrayOfCommands.Add(CommandParameters(Key._1, "TasksShowAll"));
		ArrayOfCommands.Add(CommandParameters(Key._2, "TasksUpdate"));
		ArrayOfCommands.Add(CommandParameters(Key._3, "TasksGoToTheMainMenu"));
		
	ElsIf PageName = "RequestInformationPage" Then
		
		ArrayOfCommands.Add(CommandParameters(Key._0, "InformationClose"));
		
	ElsIf PageName = "ScanPage" Then
		
		If JobType = "PickingCheck" Then
			
			ArrayOfCommands.Add(CommandParameters(Key._0, "ScanTheProduct"));
			ArrayOfCommands.Add(CommandParameters(Key._1, "ScanPurpose"));
			ArrayOfCommands.Add(CommandParameters(Key._2, "ScanNotShip", "TheLabelIsPostponed"));
			ArrayOfCommands.Add(CommandParameters(Key._3, "ScanToEnterTheNumber", "TheInscriptionWasTaken"));
			ArrayOfCommands.Add(CommandParameters(Key._4, "ScanningAnAction"));
			ArrayOfCommands.Add(CommandParameters(Key._5, "ScanEnterAValue"));
			ArrayOfCommands.Add(CommandParameters(Key._6, "ScanningService"));
			ArrayOfCommands.Add(CommandParameters(Key._7, "ScanNext"));
			
		Else
			
			ArrayOfCommands.Add(CommandParameters(Key._0, "ScanTheProduct"));
			ArrayOfCommands.Add(CommandParameters(Key._1, "ScanPurpose"));
			ArrayOfCommands.Add(CommandParameters(Key._2, "ScanToEnterTheNumber", "TheInscriptionWasTaken"));
			ArrayOfCommands.Add(CommandParameters(Key._3, "ScanningAnAction"));
			ArrayOfCommands.Add(CommandParameters(Key._4, "ScanEnterAValue"));
			ArrayOfCommands.Add(CommandParameters(Key._5, "ScanningService"));
			
			If ThisIsSetOfGoods Then
				ArrayOfCommands.Add(CommandParameters(Key._6, "ScanNext"));
			Else
				ArrayOfCommands.Add(CommandParameters(Key._6, "ScanningToCheckTheBoxToRecalculate"));
				ArrayOfCommands.Add(CommandParameters(Key._7, "ScanNext"));
			EndIf;
			
		EndIf;
		
	ElsIf PageName = "MessagePage" Then
		
		// On the message page, buttons are formed dynamically and linked to different commands.
		// To get a list of command parameters, you need to go through all the elements of the group.
		
		CounterOfAvailableCommands = 0;
		
		For Each FormButton In Form.Items.ActionTeamGroup.ChildItems Do
			If CounterOfAvailableCommands <= 9 Then
				Hotkey = Key["_" + CounterOfAvailableCommands];
				CounterOfAvailableCommands = CounterOfAvailableCommands + 1;
				ArrayOfCommands.Add(CommandParameters(Hotkey, FormButton.CommandName, FormButton.Name));
			EndIf;
		EndDo;
		
	ElsIf PageName = "PageService" Then
		
		ArrayOfCommands.Add(CommandParameters(Key._0, "ContinueScanningService"));
		
		If ChangingSeriesScanSchemeIsAvailable(Form, DeleteKeys) Then
			ArrayOfCommands.Add(CommandParameters(Key._1, "ServiceTSTSeriesScanMode"));
			ArrayOfCommands.Add(CommandParameters(Key._2, "ServiceTBTSeriesScanMode"));
		EndIf;
		
		If ChangingTraversalOrderIsAvailable(Form) Then
			ArrayOfCommands.Add(CommandParameters(Key._3, "ServiceProcessingProcedureGoodsBin"));
			ArrayOfCommands.Add(CommandParameters(Key._4, "ServiceProcessingProcedureBinGoods"));
		EndIf;
		
	ElsIf PageName = "SelectAShippingAcceptanceZonePage" Then
		
		ArrayOfCommands.Add(CommandParameters(Key._0, "SelectThePlacementAcceptanceZone"));
		ArrayOfCommands.Add(CommandParameters(Key._1, "CancelTheSelectionOfThePlacementAcceptanceZone"));
		
	ElsIf PageName = "SelectDestinationPage" Then
		
		ArrayOfCommands.Add(CommandParameters(Key._0, "SelectDestinations"));
		ArrayOfCommands.Add(CommandParameters(Key._1, "DestinationsReturn"));
		
	EndIf;
	
	Return ArrayOfCommands;
	
EndFunction

// Sets the command hotkey.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	CommandParameters - See CommandParameters
//
Procedure SetCommandHotkey(Form, CommandParameters)
	
	// Set the command hotkey.
	Command = Form.Commands[CommandParameters.CommandName]; // FormCommand
	Command.Shortcut = CommandParameters.Shortcut;
	
	// Set the title of the linked element, if it exists.
	Item = Form.Items.Find(CommandParameters.TagName);
	
	If Not (Item = Undefined) Then
		// ... in the element header, only the section of the hotkey needs to be replaced.
		ItemTitle = Item.Title;
		PresentationOfCivilCode = KeyboardShortcutPresentation(CommandParameters.Shortcut);
		
		CommandTitle = Command.Title;
		
		If Not ValueIsFilled(ItemTitle)
			And Not ValueIsFilled(CommandTitle) Then
			
			ItemTitle = PresentationOfCivilCode + ".";
			
		Else
			ItemTitle = ?(ValueIsFilled(ItemTitle), ItemTitle, CommandTitle);
			ItemTitle = IncludeHotkeyInElementTitle(ItemTitle, PresentationOfCivilCode);
		EndIf;
		
		Item.Title = ItemTitle;
	EndIf;
	
EndProcedure

// Includes the hotkey code in the element header.
//
// Parameters:
//	ItemTitle - String - item header.
//	PresentationOfCivilCode - String - representation of the hotkey code.
//
Function IncludeHotkeyInElementTitle(Val ItemTitle, PresentationOfCivilCode)
	
	If Not ValueIsFilled(PresentationOfCivilCode) Then
		Return ItemTitle;
	EndIf;
	
	// In the header of the element to which the hotkey is assigned, the first character is a digit, the second is a dot.
	ItemTitle = TrimAll(ItemTitle);
	
	If StringFunctionsClientServer.OnlyNumbersInString(Left(ItemTitle, 1)) 
		And Mid(ItemTitle, 2, 1) = "." Then
		// The element header already contains the hotkey code.
		ItemTitle = StringFunctionsClientServer.SubstituteParametersToString("%1%2", PresentationOfCivilCode + ".", Mid(ItemTitle, 3));
	Else
		// Does not contain a hotkey code.
		ItemTitle = StringFunctionsClientServer.SubstituteParametersToString("%1%2", PresentationOfCivilCode + ".", ItemTitle);
	EndIf;
	
	Return ItemTitle;
	
EndFunction

// Deletes all hotkeys on the page, because the hotkey works within
// the entire form, even if the page is hidden.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	PageName - String - page name.
//
Procedure DeleteKeyboardShortcutsOnPage(Form, PageName)
	
	CommandsParameters = CommandParametersOnFormPage(Form, PageName, True);
	EmptyCombination = New Shortcut(Key.None);
	
	For Each CommandParameters In CommandsParameters Do
		Form.Commands[CommandParameters.CommandName].Shortcut = EmptyCombination;
	EndDo;
	
EndProcedure

// Deletes all hotkeys on all pages, because the hotkey works within
// the entire form, even if the page is hidden.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** FormPages -FormGroup - a group that contains the pages of the warehouse employee's workplace form.
//
Procedure DeleteAllHotkeys(Form)
	
	Items = Form.Items;
	
	For Each Page In Items.FormPages.ChildItems Do
		PageName = Page.Name;
		DeleteKeyboardShortcutsOnPage(Form, PageName);
	EndDo;
	
EndProcedure

// Sets keyboard shortcuts for commands on elements of the current page.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** FormPages - FormGroup - a group that contains the pages of the warehouse employee's workplace form.
//
Procedure SetHotkeysOnCurPage(Form)
	
	Items = Form.Items;
	
	DeleteAllHotkeys(Form);
	CurrentPage = Items.FormPages.CurrentPage; // FormGroup
	
	CommandsParameters = CommandParametersOnFormPage(Form, CurrentPage.Name);
	
	For Each CommandParameters In CommandsParameters Do
		SetCommandHotkey(Form, CommandParameters);
	EndDo;
	
EndProcedure

// Clears the history of page clicks. Is called at the moment
// when the user returns to the main menu.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure ClearPageTrafficHistory(Form)
	
	Form.TransfersByPages.Clear();
	
EndProcedure

// Called when you go to the form page.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	PageName - String - page name.
//
Procedure WhenNavigatingToPage(Form, PageName)
	
	TransfersByPages = Form.TransfersByPages;
	
	If PageName = "ScanPage" 
		Or PageName = "OperationSelectionPage" Then
		
		TransfersByPages.Clear();
		
	EndIf;
	
	If TransfersByPages.Count() = 0 Then
		
		NewRow = TransfersByPages.Add();
		
		NewRow.PageName = PageName;
		NewRow.PageHeader = Form.Title;
		
	Else
		
		Filter = New Structure("PageName", PageName);
		RowsArray = TransfersByPages.FindRows(Filter);
		
		If RowsArray.Count() = 0 Then
			
			NewRow = TransfersByPages.Add();
			
			NewRow.PageName = PageName;
			NewRow.PageHeader = Form.Title;
			
		Else
			
			UBound = TransfersByPages.Count() - 1;
			
			For CurIndex__ = 0 To UBound Do
				
				OBRIndex = UBound - CurIndex__;
				
				PageLine = TransfersByPages[OBRIndex];
				
				If PageLine.PageName = PageName Then
					Break;
				Else
					TransfersByPages.Delete(OBRIndex);
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns whether changes to the product scanning scheme for the current task are available.
// 
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	DeleteKeys - Boolean
//
// Returns:
//	Boolean - A sign of the availability of a change in the scanning scheme of goods.
//
Function ChangingSeriesScanSchemeIsAvailable(Form, DeleteKeys = False)
	
	If (Form.ModeSettings.ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.GoodsBin)
		And Not DeleteKeys Then
		
		Return False;
		
	EndIf;
	
	JobType = Form.ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	IsFilter = (JobType = "Filter");
	ThisIsAcceptance = (JobType = "Receiving");
	ThisIsPlacement = (JobType = "Location");
	ItIsTransfer = (JobType = "Move");
	ThisIsRecalculationTask = (JobType = "Recalculate");
	ThisIsSelectionCheck = (JobType = "PickingCheck");
	
	Return (IsFilter
		Or ThisIsAcceptance
		Or ThisIsSetOfGoods
		Or ThisIsPlacement
		Or ItIsTransfer
		Or ThisIsSelectionCheck
		Or ThisIsRecalculationTask);
	
EndFunction

// Returns whether a change in the product crawl order is available.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - A sign of the availability of a change in the order of goods traversal.
//
Function ChangingTraversalOrderIsAvailable(Form)
	
	IsRecordsSet = Form.ModeSettings.SetOfProducts_;
	JobType = Form.ModeSettings.JobType;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	ScanParameter = Form.ModeSettings.ScanParameter;
	
	If IsRecordsSet Then
		Return False;
	EndIf;
	
	If Not ((JobType = "Location")
		Or (JobType = "Move"
			And SelectionScanned)) Then
		
		Return False;
		
	EndIf;
	
	If Form.ModeSettings.ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.GoodsBin Then
		If Not (ScanParameter = "Products") Then
			Return False;
		EndIf;
	EndIf;
	
	If Form.ModeSettings.ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.StorageBinGoods Then
		If Not (ScanParameter = "Cell") Then
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Returns a string representing the product.
//
// Parameters:
//	Products - CatalogRef.Products - Nomenclature.
//	Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//	Package - CatalogRef.PackagesAndUnitsOfMeasure - Packaging.
//
// Returns:
//	String - presentation of the product.
//
Function GoodsPresentation(Products = Undefined, Characteristic = Undefined, Package = Undefined)
	
	Presentation = ?(ValueIsFilled(Products), String(Products), "") + 
		?(ValueIsFilled(Characteristic), ", " + Characteristic, "") + 
		?(ValueIsFilled(Package), ", " + Package, "");
	
	Return Presentation;
	
EndFunction

// Adds the required number of characters
// to the form title text so that the title text is displayed in the middle of the form.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CenterFormHeaderText(Form)
	
	AlignmentSymbolIsLion = ".:";
	RightAlignmentSymbol = ":.";
	TitleText = Form.Title;
	
	If Not ValueIsFilled(TitleText) Then
		Return;
	EndIf;
	
	TitleText = TrimAll(TitleText);
	TextLength = StrLen(TitleText);
	
	If TextLength >= Form.FormTitleTextLengthForComparison Then
		Return;
	EndIf;
	
	NumberOfExtensionCharacters = Int((Form.TextTitleFormLength - TextLength - 4) / 2);
	ExtensionString = "";
	
	MissingCharacters = 0;
	If NumberOfExtensionCharacters > 10 Then
		MissingCharacters = Int((Form.TextTitleFormLength - 4 - (NumberOfExtensionCharacters + TextLength)) / 2);
	EndIf;
	
	NumberOfExtensionCharacters = NumberOfExtensionCharacters + MissingCharacters;
	
	// Add spaces to the title bar.
	While NumberOfExtensionCharacters > 0 Do
		ExtensionString = ExtensionString + " ";
		NumberOfExtensionCharacters = NumberOfExtensionCharacters - 1;
	EndDo;
	
	FormTitleText = AlignmentSymbolIsLion + ExtensionString + TitleText + ExtensionString +
		RightAlignmentSymbol;
	
	Form.Title = FormTitleText;
	
EndProcedure

// Returns the number of "do not ship" packages, taking into account whether the number of "in stock" packages (scanned)
//	is not allowed, and whether the quantity of goods that exceeds the quantity in the document is not allowed to be shipped.
//
// Parameters:
//	ScanLine - See ScanLine
//	PermissibleDeviationOfSelectedGoods - Number
//
// Returns:
//	Number - adjusted number of unloaded packages.
//
Function AdjustedNumberOfPackagesDoNotShip(ScanLine, PermissibleDeviationOfSelectedGoods = 0)
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	ThisIsMeasuredCommodity = DimensionalUnitsOfMeasurement.Find(ScanLine.MeasuredValueType) <> Undefined;
	
	If ThisIsMeasuredCommodity Then
		MaximumQuantityOfShippedGoods = ScanLine.NumberOfPackagesInDocument +
			ScanLine.NumberOfPackagesInDocument * PermissibleDeviationOfSelectedGoods / 100;
		
		If ScanLine.NumberOfPackagingsScanned > MaximumQuantityOfShippedGoods Then
			Return Max(ScanLine.NumberOfPackagingsScanned - ScanLine.NumberOfPackagesInDocument,
				Min(ScanLine.NumberOfPackagesDoNotShip, ScanLine.NumberOfPackagingsScanned));
		Else
			Return Max(ScanLine.NumberOfPackagingsScanned - MaximumQuantityOfShippedGoods,
				Min(ScanLine.NumberOfPackagesDoNotShip, ScanLine.NumberOfPackagingsScanned));
		EndIf;
	Else
		Return Max(ScanLine.NumberOfPackagingsScanned - ScanLine.NumberOfPackagesInDocument,
			Min(ScanLine.NumberOfPackagesDoNotShip, ScanLine.NumberOfPackagingsScanned));
	EndIf;
	
EndFunction

Function CheckPackingList(Form, OwnGoods)
	
	ScannedPackingSheets = Form.ScannedGoods.Unload(
		New Structure("ThisIsAPackingList", True), "PackingList").UnloadColumn("PackingList");
	
	PackingListScanned = WorkplaceOfWarehouseWorkerApplicationInterface.PackingListScanned(
		OwnGoods.PackingList, ScannedPackingSheets);
	
	If Not PackingListScanned Then
		OwnGoods.ReturnCode = 0;
		OwnGoods.ErrorType = "UpSheetContainsPreviouslyScannedUpSheets";
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function Assignments(Form, OwnGoods = Undefined, ForAutoSelection = False)
	
	Object = Form.Object;
	ModeSettings = Form.ModeSettings;
	DocumentGoods = Form.ScannedGoods.Unload(, "Products, Characteristic, Purpose, Count");
	
	If OwnGoods = Undefined Then
		OwnGoods = OwnGoods();
		FillPropertyValues(OwnGoods, Form.CurrentScanningLine);
	EndIf;
	
	Assignments = WorkplaceOfWarehouseWorkerApplicationInterface.Assignments(Object.Warehouse, Object.ReferenceOrder,
		Form.CurrentScanningLine.Cell, OwnGoods, DocumentGoods, ModeSettings, ForAutoSelection);
	
	Return Assignments;
	
EndFunction

// Sets the conditional elements of the warehouse employee's workplace form.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetConditionalAppearance(Form)
	
	Form.ConditionalAppearance.Items.Clear();
	
	// Sets the conditional design of the "Assignation" field of the PM of the "Destination" object.
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AssignmentsPurpose");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Assignments.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không mục đích>';
													|ru = '<без назначения>';
													|en = '<No assignment>'; fa = '<No assignment>';
													|it = '<senza assegnazione>';
													|pl = '<bez przeznaczenia>';
													|tr = '<atamasız>'"));
	
	// Sets the conditional design of the "Destination" field of the PM of the "Destination" object.
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AssignmentsBalance");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Assignments.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", "");
	
	// Sets the conditional design of the field "Task Executor" of the PM form "Tasks"
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("JobsPerformer");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Jobs.Performer");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	If Form.ScreenResolution = Enums.ScreenResolutions.Resolution240x320 Then
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
														|ru = '<не указан>';
														|en = '<Not specified>'; fa = '<مشخص نشده>';
														|it = '<non specificato>';
														|pl = '<nie określono>';
														|tr = '<belirtilmedi>'"));
	Else
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có người thực hiện được chỉ định>';
														|ru = '<исполнитель не указан>';
														|en = '<Assignee not specified>'; fa = '<Assignee not specified>';
														|it = '<assegnatario non è indicato>';
														|pl = '<nie wskazano wykonawcy>';
														|tr = '<atanan belirtilmedi>'"));
	EndIf;
	
	// Sets the conditional design of the field "Task Order" of the PM form "Tasks".
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("JobsDeliveryProcedure");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Jobs.DeliveryProcedure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	If Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640 Then
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<lệnh giao hàng không được chỉ định>';
														|ru = '<порядок доставки не указан>';
														|en = '<Delivery sequence not specified>'; fa = '<ترتیب تحویل مشخص نشده است>';
														|it = '<sequenza di consegna non specificata>';
														|pl = '<nie wskazano kolejności dostawy>';
														|tr = '<teslimat düzeni belirtilmedi>'"));
	ElsIf Form.ScreenResolution = Enums.ScreenResolutions.Resolution320x320 Then
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<quy trình không được chỉ định>';
														|ru = '<порядок не указан>';
														|en = '<Sequence not specified>'; fa = '<Sequence not specified>';
														|it = '<ordine non specificato>';
														|pl = '<kolejność nie jest określona>';
														|tr = '<düzen belirtilmedi>'"));
	Else
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
														|ru = '<не указан>';
														|en = '<Not specified>'; fa = '<مشخص نشده>';
														|it = '<non specificato>';
														|pl = '<nie określono>';
														|tr = '<belirtilmedi>'"));
	EndIf;
	
EndProcedure

// Checks whether packing lists can be used in the warehouse task.
//
// Parameters:
//	JobType - String - type of flexible task.
//
//
// Returns:
//	Boolean - True if packing lists can be used in the warehouse task.
//
Function PackingListsCanBeUsedInJob(JobType)
	
	Return JobType = "Receiving"
		Or JobType = "PickingCheck";
	
EndFunction

// Fills in the PM of the object in the form < leftover goods in the Cell> to resolve the 480x640 form, depending on the type
// of operation being performed.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* CellsForScanning - TabularSection - a table containing information about the scanned cells in the warehouse task.
//	ThisIsGoodSelectionOfGoods - Boolean - flag that determines the algorithm for filling in PM data, in cases
//		of selection/placement of products from other cells that are not specified in the original version of the task.
//
Procedure FillInRemainingItemsInCell(Form, ThisIsGoodSelectionOfGoods = False)
	
	If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
		Return;
	EndIf;
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	
	If JobType = "Receiving" 
		Or JobType = "PickingCheck"
		Or JobType = "Recalculate" Then
		
		Return;
		
	EndIf;
	
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	StockOfGoodsInBin = Form.Object.StockOfGoodsInBin;
	
	If JobType = "Filter"
		Or (JobType = "Location"
			And Not ThisIsSetOfGoods)
		Or (JobType = "Move"
			And Not SelectionScanned) Then
		
		VTCellsForScanning = Form.CellsForScanning.Unload();
		CellsForScanning = VTCellsForScanning.UnloadColumn("Cell");
		
		If Not ThisIsGoodSelectionOfGoods Then
			StockOfGoodsInBin.Clear();
		Else
			CurCell_ = Form.CurrentScanningLine.Cell;
			VTBalancesOfGoodsInCell = StockOfGoodsInBin.Unload();
			VTBalancesOfGoodsInCell.Clear();
			ArrayOfCells = New Array;
			
			For Each CellRowToScan In VTCellsForScanning Do
				If CellRowToScan.Scanned 
					Or CellRowToScan.Cell = CurCell_ Then
					
					Filter = New Structure("Cell", CellRowToScan.Cell);
					RowsArray = StockOfGoodsInBin.FindRows(Filter);
					
					For Each String In RowsArray Do
						NewRow = VTBalancesOfGoodsInCell.Add();
						FillPropertyValues(NewRow, String);
					EndDo;
					
				Else
					ArrayOfCells.Add(CellRowToScan.Cell);
				EndIf;
			EndDo;
			
			StockOfGoodsInBin.Clear();
			
			For Each LineVtBalancesOfGoods In VTBalancesOfGoodsInCell Do
				NewRow = StockOfGoodsInBin.Add();
				FillPropertyValues(NewRow, LineVtBalancesOfGoods);
			EndDo;
			
		EndIf;
		
		If JobType = "Move" Then
			GoodsPlacement = Form.Object.GoodsPlacement.Unload();
			CellsProductsPlacement = GoodsPlacement.UnloadColumn("Cell");
			
			UniqueCellProductsPlacement = New Array;
			CommonClientServer.SupplementArray(UniqueCellProductsPlacement, CellsProductsPlacement, True);
			
			For Each CellPlacement In UniqueCellProductsPlacement Do
				CellsForScanning.Add(CellPlacement);
			EndDo;
		EndIf;
		
		If Not ThisIsGoodSelectionOfGoods Then
			ArrayOfCells = New Array;
			CommonClientServer.SupplementArray(ArrayOfCells, CellsForScanning, True);
		EndIf;
		
		StockBalance = WorkplaceOfWarehouseWorkerApplicationInterface.StockOfGoodsInBin(ArrayOfCells);
		
		For Each RemainderLine_ In StockBalance Do
			NewRow = StockOfGoodsInBin.Add();
			FillPropertyValues(NewRow, RemainderLine_);
		EndDo;
		
	ElsIf JobType = "Move"
		And SelectionScanned Then
		
		For Each ItemBalancesLine In StockOfGoodsInBin Do
			ItemBalancesLine.Count = ItemBalancesLine.QuantityScanned;
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the PM object of the <product for Recalculation> form to resolve the 480x640 form in recalculation tasks.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure FillInItemsForRecalculation(Form)
	
	If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
		Return;
	EndIf;
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	
	If Not JobType = "Recalculate" Then
		Return;
	EndIf;
	
	InventoryToRecount = Form.Object.InventoryToRecount;
	InventoryToRecount.Clear();
	
	VTCellsForScanning = Form.CellsForScanning.Unload();
	CellsForScanning = VTCellsForScanning.UnloadColumn("Cell");
	
	ArrayOfCells = New Array;
	CommonClientServer.SupplementArray(ArrayOfCells, CellsForScanning, True);
	
	InventoryToRecount.Load(
		WorkplaceOfWarehouseWorkerApplicationInterface.InventoryToRecount(ArrayOfCells));
	
EndProcedure

// Updates PM data <leftover goods in the Cell>/<Product for the calculation> for the resolution of the 480x640 form
// , depending on the current cell being scanned.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** InventoryToRecount -FormTable - a table that stores information about inventory items in cells.
//			** StockOfGoodsInBin -FormTable - a table that stores information about product balances in cells.
//	CurrentScanningLine - See ScanLine
//
Procedure WhenMovingToNextCellRemainingItemsInCell(Form, CurrentScanningLine)
	
	If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
		Return;
	EndIf;
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	
	If JobType = "Receiving" 
		Or JobType = "PickingCheck" Then
		
		Return;
		
	EndIf;
	
	If JobType = "Recalculate" Then
		
		InventoryToRecount = Form.Object.InventoryToRecount;
		
		Filter = New Structure("Cell", CurrentScanningLine.Cell);
		Items.InventoryToRecount.RowFilter = New FixedStructure(Filter);
		
		RowsArray = InventoryToRecount.FindRows(Filter);
		
		If RowsArray.Count() > 0 Then
			Items.InventoryToRecount.CurrentRow = RowsArray[0].GetID();
		EndIf;
		
	Else
		
		StockOfGoodsInBin = Form.Object.StockOfGoodsInBin;
		
		Filter = New Structure("Cell", CurrentScanningLine.Cell);
		Items.StockOfGoodsInBin.RowFilter = New FixedStructure(Filter);
		
		If ThisIsTara(CurrentScanningLine) Then
			Filter = New Structure("Cell, Products, Characteristic, Purpose");
		Else
			If (JobType = "Filter"
					Or JobType = "Move")
				And SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) Then
				
				Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber, ValidUntil_");
				
			Else
				Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
			EndIf;
		EndIf;
		
		FillPropertyValues(Filter, CurrentScanningLine);
		RowsArray = StockOfGoodsInBin.FindRows(Filter);
		If RowsArray.Count() = 0 Then
			Return;
		Else
			ItemBalancesLine = RowsArray[0];
			StockOfGoodsInBin.Delete(ItemBalancesLine);
			
			NewRow = StockOfGoodsInBin.Insert(0);
			FillPropertyValues(NewRow, ItemBalancesLine);
			
			Items.StockOfGoodsInBin.CurrentRow = NewRow.GetID();
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in PM < leftover goods in the Cell>/<Product for account> for 480x640 form resolution
// props packaging for the item type tare.
//
// Parameters:
//	Form-Formaclientapplication - a form for processing the mobile workplace of a warehouse employee.
//	TSRow - LineOfATabularSection - a line of the table part of the remaining items in the cell or items to be recalculated.
//
Procedure SetUnitOfMeasurementOfTareGoodsResiduesOfGoodsInCell(TSRow)
	
	If ThisIsTara(TSRow.Products) Then
		UnitOfMeasure = Common.ObjectAttributeValue(TSRow.Products, "UnitOfMeasure");
		TSRow.Package = UnitOfMeasure;
	EndIf;
	
EndProcedure

// Updates the number of product balances in the PM < leftover goods Cell> to resolve the 480x640 form
// , depending on the type of operation being performed.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** StockOfGoodsInBin -FormTable - a table that stores information about product balances in cells.
//	QuantityToAdd - Number - the number of products that will be used when adding a line to the TOR <scanned Goods>.
//
Procedure SetNumberOfBalancesToProductBalancesInCell(Form, QuantityToAdd = Undefined)
	
	If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
		Return;
	EndIf;
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	StockOfGoodsInBin = Form.Object.StockOfGoodsInBin;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If JobType = "PickingCheck" Then
		Return;
	EndIf;
	
	ThisIsPlacement = (JobType = "Location");
	SelectionScanned = ModeSettings.SelectionScanned;
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(ModeSettings.ProcessingProcedure_);
	
	If JobType = "Move" Then
		ThisIsPlacement = SelectionScanned;
	EndIf;
	
	If ThisIsTara(CurrentScanningLine) Then
		Filter = New Structure("Cell, Products, Characteristic, Purpose");
	Else
		If (JobType = "Filter"
				Or JobType = "Move")
			And SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) Then
			
			Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, BatchNumber, ValidUntil_");
			
		Else
			Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
		EndIf;
	EndIf;
	
	FillPropertyValues(Filter, CurrentScanningLine);
	
	If ThisIsProcessingOrderOfItemCell Then
		
		RowsArray = StockOfGoodsInBin.FindRows(Filter);
		If RowsArray.Count() > 0 Then
			ItemBalancesLine = RowsArray[0];
			StockOfGoodsInBin.Delete(ItemBalancesLine);
			
			NewRow = StockOfGoodsInBin.Insert(0);
			FillPropertyValues(NewRow, ItemBalancesLine);
		Else
			NewRow = StockOfGoodsInBin.Insert(0);
			FillPropertyValues(NewRow, CurrentScanningLine);
			NewRow.BatchPresentation = SetSeriesPresentation(CurrentScanningLine);
		EndIf;
		
		NewRow.QuantityScanned = NewRow.Count + CurrentScanningLine.NumberOfPackagesPut 
			+ CurrentScanningLine.NumberOfPackagesToPut;
		
		If ThisIsTara(CurrentScanningLine) Then
			SetUnitOfMeasurementOfTareGoodsResiduesOfGoodsInCell(ItemBalancesLine);
		EndIf;
		
		WhenMovingToNextCellRemainingItemsInCell(Form, CurrentScanningLine);
		Items.StockOfGoodsInBin.CurrentRow = NewRow.GetID();
		
	Else
		
		RowsArray = StockOfGoodsInBin.FindRows(Filter);
		If RowsArray.Count() > 0 Then
			ItemBalancesLine = RowsArray[0];
			StockOfGoodsInBin.Delete(ItemBalancesLine);
			
			NewRow = StockOfGoodsInBin.Insert(0);
			FillPropertyValues(NewRow, ItemBalancesLine);
		Else
			NewRow = StockOfGoodsInBin.Insert(0);
			FillPropertyValues(NewRow, CurrentScanningLine);
			NewRow.BatchPresentation = SetSeriesPresentation(CurrentScanningLine);
		EndIf;
		
		If ThisIsTara(CurrentScanningLine) Then
			SetUnitOfMeasurementOfTareGoodsResiduesOfGoodsInCell(NewRow);
		EndIf;
		
		QuantityScanned = CurrentScanningLine.NumberOfPackagingsScanned;
		If SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) Then
			If QuantityToAdd = 1 Then
				QuantityScanned = 1;
			Else
				QuantityScanned = QuantityToAdd;
			EndIf;
			
			If ThisIsPlacement Then
				NewRow.QuantityScanned = NewRow.QuantityScanned + QuantityScanned;
			Else
				NewRow.QuantityScanned = NewRow.QuantityScanned - QuantityScanned;
			EndIf;
		Else
			If ThisIsPlacement Then
				NewRow.QuantityScanned = NewRow.Count + QuantityScanned;
			Else
				NewRow.QuantityScanned = NewRow.Count - QuantityScanned;
			EndIf;
		EndIf;
		
		Items.StockOfGoodsInBin.CurrentRow = NewRow.GetID();
		
	EndIf;
	
EndProcedure

// Updates the actual number of product balances in PM < product for Recalculation> to resolve the 480x640 form
// , depending on the type of operation performed.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** InventoryToRecount -FormTable - a table that stores information about inventory items in cells.
//
Procedure SetQuantityForAccountingInGoodsForRecalculation(Form)
	
	If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
		Return;
	EndIf;
	
	Items = Form.Items;
	ModeSettings = Form.ModeSettings;
	InventoryToRecount = Form.Object.InventoryToRecount;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If Not ModeSettings.JobType = "Recalculate" Then
		Return;
	EndIf;
	
	If ThisIsTara(CurrentScanningLine) Then
		Filter = New Structure("Cell, Products, Characteristic, Purpose");
		SelectionWithoutSeries = New Structure("Cell, Products, Characteristic, Purpose");
	Else
		Filter = New Structure("Cell, Products, Characteristic, Purpose, Package, Series");
		SelectionWithoutSeries = New Structure("Cell, Products, Characteristic, Purpose, Package");
	EndIf;
	
	FillPropertyValues(Filter, CurrentScanningLine);
	FillPropertyValues(SelectionWithoutSeries, CurrentScanningLine);
	
	RowsArray = InventoryToRecount.FindRows(Filter);
	If RowsArray.Count() > 0 Then
		LineForRecalculation = RowsArray[0];
		InventoryToRecount.Delete(LineForRecalculation);
		
		NewRow = InventoryToRecount.Insert(0);
		FillPropertyValues(NewRow, LineForRecalculation);
	Else
		NewRow = InventoryToRecount.Insert(0);
		FillPropertyValues(NewRow, CurrentScanningLine);
	EndIf;
	
	If ThisIsTara(CurrentScanningLine) Then
		SetUnitOfMeasurementOfTareGoodsResiduesOfGoodsInCell(NewRow);
	EndIf;
	
	NewRow.QuantityScanned = CurrentScanningLine.NumberOfPackagingsScanned;
	Items.InventoryToRecount.CurrentRow = NewRow.GetID();
	
EndProcedure

// Updates data about the volume and weight of the scanned product in the tasks of acceptance and creation of a new placement
// for the resolution of the 480x640 form.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	ScannedProductsLine - LineOfATabularSection- a line in the table part of scanned products.
//	IsNewLine - Boolean - True if this is a new row in the table part of the scanned products.
//
Procedure FillInParametersOfScannedProduct(Form, ScannedProductsLine, IsNewLine = False)
	
	If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
		Return;
	EndIf;
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If JobType = "Filter"
		Or (JobType = "Location"
			And Not ThisIsSetOfGoods)
		Or JobType = "Move"
		Or JobType = "Recalculate"
		Or JobType = "PickingCheck" Then
		
		Return;
		
	EndIf;
	
	If IsNewLine Then
		PackingDetails = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(
			CurrentScanningLine.Package, CurrentScanningLine.Products, ,False);
		
		ScannedProductsLine.PackageWeight = PackingDetails.Weight;
		ScannedProductsLine.PackageVolume = PackingDetails.VolumeM3;
	EndIf;
	
	ScannedProductsLine.Weight = 
		ScannedProductsLine.PackageWeight * ScannedProductsLine.NumberOfPackagingsScanned;
	ScannedProductsLine.VolumeM3 = 
		ScannedProductsLine.PackageVolume * ScannedProductsLine.NumberOfPackagingsScanned;
	
EndProcedure

// Displays data about the volume and weight of scanned items in the tasks for accepting and creating a new placement
// for the resolution of the 480x640 form.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetParametersOfScannedProducts(Form)
	
	If Not (Form.ScreenResolution = Enums.ScreenResolutions.Resolution480x640) Then
		Return;
	EndIf;
	
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	ScannedGoods = Form.ScannedGoods;
	
	If JobType = "Filter" 
		Or (JobType = "Location" 
		And Not ThisIsSetOfGoods)
		Or JobType = "Move" 
		Or JobType = "Recalculate" 
		Or JobType = "PickingCheck" Then
		
		Return;
		
	EndIf;
	
	Form.WeightOfScannedGoods = String(ScannedGoods.Total("Weight")) + " " + String(Form.UnitOfMeasureForWeight);
	Form.ScannedGoodsAmount = 
		String(ScannedGoods.Total("VolumeM3")) + " " + String(Form.UnitOfMeasureForVolume);
	
EndProcedure

// Supplements the TOR of the <product Scanning > form with lines in the selection/placement operations if
// not all products were selected/placed from the cell in accordance with the task being performed.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* GoodsForScanning - FormDataCollection - table of scanned items in the warehouse task.
//	ThisJumpsToNextCell - Boolean - True if you are moving to the next scan line
//											of a warehouse task that contains information about a warehouse cell other than the current line.
//
Procedure AddItemsNotSelectedToTableForScanningItems(Form, ThisJumpsToNextCell)
	
	Warehouse = Form.Object.Warehouse;
	Premise = Form.Object.Premise;
	ReferenceOrder = Form.Object.ReferenceOrder;
	Job = Form.ModeSettings.Job;
	JobType = Form.ModeSettings.JobType;
	CurCell = Form.CurrentScanningLine.Cell;
	GoodsForScanning = Form.GoodsForScanning;
	
	If CurCell = Catalogs.StorageBins.EmptyRef() Then
		Return;
	EndIf;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If Not (JobType = "Filter"
		Or JobType = "Location")
		Or ThisIsProcessingOrderOfItemCell Then
		
		Return;
		
	EndIf;
	
	// The goods that should be selected/placed from other cells are selected if
	// the goods from the current cell were not selected/placed in accordance with the task.
	If ThisJumpsToNextCell Then
		ProductsSelected_1 = True;
		Filter = New Structure("ActiveString", 1);
		ActiveString = GoodsForScanning.FindRows(Filter)[0];
		
		If ActiveString.NumberOfPackages = ActiveString.NumberOfPackagingsScanned Then
			Return;
		EndIf;
		
		RowsArray = New Array;
		IndexOfRowToBeSelected = GoodsForScanning.IndexOf(ActiveString);
		UBound = GoodsForScanning.Count() - 1;
		
		While ProductsSelected_1 Do
			FIlterRow = GoodsForScanning.Get(IndexOfRowToBeSelected);
			If FIlterRow.Cell = CurCell Then
				RowsArray.Add(FIlterRow);
				IndexOfRowToBeSelected = IndexOfRowToBeSelected + 1;
				
				If IndexOfRowToBeSelected > UBound Then
					Break;
				EndIf;
			Else
				Break;
			EndIf;
		EndDo;
		
	Else
		Filter = New Structure("ActiveString", 1);
		RowsArray = GoodsForScanning.FindRows(Filter);
		
		If RowsArray[0].NumberOfPackages = RowsArray[0].NumberOfPackagingsScanned Then
			Return;
		EndIf;
	EndIf;
	
	WorkplaceOfWarehouseWorkerApplicationInterface.MarkABinForRecount(CurCell);
	
	GoodsForPicking = GoodsForScanning.Unload(RowsArray, "Products, Package, Characteristic, Purpose, 
		|Series, ItemsType, ZoomRatio, NumberOfPackages, NumberOfPackagingsScanned");
	GoodsForPicking.Columns.Add("Count", New TypeDescription("Number", , , New NumberQualifiers(15, 3, 
		AllowedSign.Nonnegative)));
	
	// We remove the lines with the goods that were selected/placed in accordance with the task from the TK <Product Selection>.
	LinesToDelete = New Array;
	For Each RowOfGoods In GoodsForPicking Do
		If RowOfGoods.NumberOfPackages > RowOfGoods.NumberOfPackagingsScanned Then
			RowOfGoods.NumberOfPackages = RowOfGoods.NumberOfPackages - RowOfGoods.NumberOfPackagingsScanned;
			If ThisIsTara(RowOfGoods)
				Or (RowOfGoods.ZoomRatio = 0) Then
				RowOfGoods.Count = RowOfGoods.NumberOfPackages;
			Else
				RowOfGoods.Count = RowOfGoods.NumberOfPackages * RowOfGoods.ZoomRatio;
			EndIf;
		Else
			LinesToDelete.Add(RowOfGoods);
		EndIf;
	EndDo;
	
	If LinesToDelete.Count() > 0 Then
		For Each String In LinesToDelete Do
			GoodsForPicking.Delete(String);
		EndDo;
	EndIf;
	
	ResultStructure1 = WorkplaceOfWarehouseWorkerApplicationInterface.TableOfUnselectedProducts(Warehouse, Premise,
		GoodsForPicking, ReferenceOrder, Job);
	
	If ResultStructure1 = Undefined Then
		Form.ModeSettings.DisplayWarningWhenScanning = True;
		Form.ModeSettings.MessageID_ = "CellsAreNotMatched";
		
		EventName = NStr("vi = 'Lỗi khi lựa chọn ô để thực hiện giao dịch kho bãi lấy ra (sắp xếp) hàng hóa';
						|ru = 'Ошибка при подборе ячеек для выполнения складской операции отбора (размещения) товаров';
						|en = 'Cannot find a storage bin to transfer the inventory'; fa = 'Cannot find a storage bin to transfer the inventory';
						|it = 'Errore durante la selezione delle celle per l''esecuzione dell''operazione di magazzino per la selezione (collocamento) delle merci';
						|pl = 'Błąd przy doborze komórek dla wykonywania operacji magazynowej wyboru(umieszczenia) towarów';
						|tr = 'Ürün filtresi (yerleştirme) ambar işlemini gerçekleştirmek için hücre seçerken hata'",
			Common.DefaultLanguageCode());
		
		For Each Message In GetUserMessages(True) Do
			WriteLogEvent(EventName, EventLogLevel.Error, , , Message.Text);
		EndDo;
		
		Return;
	Else
		ResultsTable = ResultStructure1.ResultsTable;
	EndIf;
	
	ResultTableCells = ResultsTable.UnloadColumn("Cell");
	CellsToAdd = New Array;
	CommonClientServer.SupplementArray(CellsToAdd, ResultTableCells, True);
	
	CellsForScanning = Form.CellsForScanning;
	ScannedCells = New Array;
	NotScannedCells = New Array;
	
	For Each RowOfScanCells In CellsForScanning Do
		If RowOfScanCells.Scanned 
			Or CurCell = RowOfScanCells.Cell Then
			
			ScannedCells.Add(RowOfScanCells.Cell);
			
		Else
			NotScannedCells.Add(RowOfScanCells.Cell);
		EndIf;
	EndDo;
	
	// We delete the rows with goods from the received TK, according to the current cell or cells that were scanned earlier.
	For Each Cell In CellsToAdd Do
		If (Cell = CurCell) 
			Or Not (ScannedCells.Find(Cell) = Undefined) Then
			
			Filter = New Structure("Cell", Cell);
			RowsArray = ResultsTable.FindRows(Filter);
			
			For Each String In RowsArray Do
				ResultsTable.Delete(String);
			EndDo;
		EndIf;
	EndDo;
	
	If ResultsTable.Count() = 0 Then
		Form.ModeSettings.DisplayWarningWhenScanning = True;
		Form.ModeSettings.MessageID_ = "CellsAreNotMatched";
		Return;
	EndIf;
	
	VTResultsTable = ResultsTable.Copy(); // ValueTable
	VTResultsTable.GroupBy("Products, Characteristic, Package, Purpose, Series", "NumberOfPackages");
	
	// We update the number of goods of the TK <Product for Scanning> in the current cell, depending on the data of the TK with the goods
	// that need to be selected/placed from other cells.
	For Each ResultTableRow In VTResultsTable Do
		
		Filter = New Structure("Products, Characteristic, Package, Purpose, Series");
		FillPropertyValues(Filter, ResultTableRow);
		
		RowsArray = GoodsForPicking.FindRows(Filter);
		Filter.Insert("Cell", CurCell);
		
		If RowsArray.Count() > 0 Then
			
			If ThisIsTara(ResultTableRow.Products) Then
				
				// containers are distributed
				If RowsArray.Count() > 1 Then
					
					DistributionQuantity = ResultTableRow.NumberOfPackages;
					RowsArray = GoodsForScanning.FindRows(Filter);
					
					For Each String In RowsArray Do
						
						If String.NumberOfPackages < DistributionQuantity Then
							DistributionQuantity = DistributionQuantity - String.NumberOfPackages;
							String.NumberOfPackages = String.NumberOfPackagingsScanned;
						Else
							If DistributionQuantity = String.NumberOfPackagingsScanned Then
								String.NumberOfPackages = String.NumberOfPackagingsScanned;
							Else
								String.NumberOfPackages = String.NumberOfPackages - DistributionQuantity;
							EndIf;
							
							Break;
						EndIf;
						
					EndDo;
					
				Else
					
					Filter.Insert("ZoomRatio", RowsArray[0].ZoomRatio);
					ScanProductLine = GoodsForScanning.FindRows(Filter)[0];
					
					If RowsArray[0].NumberOfPackages = ResultTableRow.NumberOfPackages Then
						ScanProductLine.NumberOfPackages = ScanProductLine.NumberOfPackagingsScanned;
					Else
						ScanProductLine.NumberOfPackages = 
							ScanProductLine.NumberOfPackages - ResultTableRow.NumberOfPackages;
					EndIf;
					
				EndIf;
				
			Else
				
				// goods are distributed
				ScanProductLine = GoodsForScanning.FindRows(Filter)[0];
				If RowsArray[0].NumberOfPackages = ResultTableRow.NumberOfPackages Then
					ScanProductLine.NumberOfPackages = ScanProductLine.NumberOfPackagingsScanned;
				Else
					ScanProductLine.NumberOfPackages = 
						ScanProductLine.NumberOfPackages - ResultTableRow.NumberOfPackages;
				EndIf;
				
			EndIf;
			
		Else
			
			// the goods are distributed as a multi-turn container
			DistributionQuantity = ResultTableRow.NumberOfPackages;
			RowsArray = GoodsForScanning.FindRows(Filter);
			
			For Each String In RowsArray Do
				
				If String.NumberOfPackages < DistributionQuantity Then
					DistributionQuantity = DistributionQuantity - String.NumberOfPackages;
					String.NumberOfPackages = String.NumberOfPackagingsScanned;
				Else
					If DistributionQuantity = String.NumberOfPackagingsScanned Then
						String.NumberOfPackages = String.NumberOfPackagingsScanned;
					Else
						String.NumberOfPackages = String.NumberOfPackages - DistributionQuantity;
					EndIf;
					
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	VTProductsForScanning = Form.GoodsForScanning.Unload();
	VTProductsForScanning.Clear();
	
	// We fill in the TOR with data about the un-scanned lines.
	For Each Cell In NotScannedCells Do
		
		Filter = New Structure("Cell", Cell);
		RowsArray = GoodsForScanning.FindRows(Filter);
		
		For Each String In RowsArray Do
			GoodsForScanning.Delete(String);
			
			NewRow = VTProductsForScanning.Add();
			FillPropertyValues(NewRow, String);
		EndDo;
		
	EndDo;
	
	// We fill in the TK with data from the TK with goods that need to be selected / placed from other cells.
	For Each ProductLineToAdd In ResultsTable Do
		NewRow = VTProductsForScanning.Add();
		FillPropertyValues(NewRow, ProductLineToAdd);
		
		Filter = New Structure("Products, Characteristic, Purpose, Package, Series");
		FillPropertyValues(Filter, ProductLineToAdd);
		
		RowsArray = GoodsForScanning.FindRows(Filter);
		
		NewRow.ProductKind = RowsArray[0].ProductKind;
		NewRow.ItemsType = RowsArray[0].ItemsType;
		NewRow.ItemsBarcode = RowsArray[0].ItemsBarcode;
		
		NewRow.BatchNumber = RowsArray[0].BatchNumber;
		NewRow.ValidUntil_ = RowsArray[0].ValidUntil_;
		
		NewRow.SpecifyNumberWhenRegisteringBatch = RowsArray[0].SpecifyNumberWhenRegisteringBatch;
		NewRow.UseShelfLifeOnBatchRegistration = RowsArray[0].UseShelfLifeOnBatchRegistration;
		NewRow.PrecisionOfBatchShelfLifeIndication = RowsArray[0].PrecisionOfBatchShelfLifeIndication;
		
		NewRow.ZoomRatio = RowsArray[0].ZoomRatio;
		NewRow.FactorOfWeightUnitOfMeasure = RowsArray[0].FactorOfWeightUnitOfMeasure;
		NewRow.FactorOfVolumeUnitOfMeasure = RowsArray[0].FactorOfVolumeUnitOfMeasure;
		
		NewRow.PackageWeight = RowsArray[0].PackageWeight;
		NewRow.PackageVolume = RowsArray[0].PackageVolume;
		
		NewRow.UnitOfMeasure = RowsArray[0].UnitOfMeasure;
		NewRow.UnitOfMeasureForWeight = RowsArray[0].UnitOfMeasureForWeight;
		NewRow.UnitOfMeasureForVolume = RowsArray[0].UnitOfMeasureForVolume;
		NewRow.MeasuredValueType = RowsArray[0].MeasuredValueType;
		
	EndDo;
	
	ArrayOfResultTableCells = New Array;
	ResultTableCells = ResultsTable.UnloadColumn("Cell");
	CommonClientServer.SupplementArray(ArrayOfResultTableCells, ResultTableCells, True);
	
	CellsWithBarcodes = WorkplaceOfWarehouseWorkerApplicationInterface.CellBarcodes(ArrayOfResultTableCells);
	
	For Each Cell In CellsWithBarcodes Do
		Filter = New Structure("Cell", Cell.Cell);
		RowsArray = VTProductsForScanning.FindRows(Filter);
		
		For Each String In RowsArray Do
			FillPropertyValues(String, Cell);
		EndDo;
	EndDo;
	
	VTProductsForScanning = WorkplaceOfWarehouseWorkerApplicationInterface.ProductQueueForScanning(Warehouse,
		Premise, VTProductsForScanning, CurCell);
	
	For Each LineOfVTForScanningProducts In VTProductsForScanning Do
		NewRow = GoodsForScanning.Add();
		FillPropertyValues(NewRow, LineOfVTForScanningProducts);
		
		NewRow.NumberOfPackagesInDocument = NewRow.NumberOfPackages;
		
		Filter = New Structure("Products, Characteristic, Package");
		FillPropertyValues(Filter, NewRow);
		
		RowsArray = GoodsForScanning.FindRows(Filter);
		NewRow.BatchesIndicationStatus = RowsArray[0].BatchesIndicationStatus;
	EndDo;
	
	NotScannedCells = New Array;
	AddedCells = VTProductsForScanning.UnloadColumn("Cell");
	CommonClientServer.SupplementArray(NotScannedCells, AddedCells, True);
	
	CellsForScanning.Clear();
	
	For Each NewCell In ScannedCells Do
		NewRow = CellsForScanning.Add();
		
		NewRow.Cell = NewCell;
		NewRow.Scanned = 1;
		NewRow.CellNumber = CellsForScanning.Count();
	EndDo;
	
	For Each NewCell In NotScannedCells Do
		NewRow = CellsForScanning.Add();
		
		NewRow.Cell = NewCell;
		NewRow.Scanned = 0;
		NewRow.CellNumber = CellsForScanning.Count();
	EndDo;
	
	NumberOfBins = CellsForScanning.Count();
	
	For Each Cell In CellsForScanning Do
		Cell.NumberOfBins = NumberOfBins;
	EndDo;
	
	FillInServiceInformationOfGoodsForScanning(Form);
	
	// Clearing the scan queue of rows with zero number of products.
	ArrayOfEmptyStrings = New Array;
	For Each ScanLine In GoodsForScanning Do
		If ScanLine.NumberOfPackages = 0 
			And Not ScanLine.ActiveString = 1 Then
			
			ArrayOfEmptyStrings.Add(ScanLine);
			
		EndIf;
	EndDo;
	
	For Each IsBlankString In ArrayOfEmptyStrings Do
		GoodsForScanning.Delete(IsBlankString);
	EndDo;
	
	FillInRemainingItemsInCell(Form, True);
	
EndProcedure

// The procedure is called when you click the "pick up items from other cells" button
// On the message to user page, after the user has selected the action "move to the next Cell".
// The procedure "includes" an algorithm for selecting products for selection/placement from / in other cells.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SelectGoodsFromOtherBinsWhileTransferringToTheNextBin(Form) Export
	
	GoToTheNextBin(Form, True);
	HandleWarningWhenScanningValue(Form);
	
EndProcedure

// The procedure is called when you click the" cancel boardingfrom other cells "
// button on the message to user page, after the user has selected the action "re-Enter the next Cell".
// The procedure "disables" the algorithm for selecting products for selection/placement from / in other cells.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CancelGoodsPickingFromOtherBinsWhileTransferringToTheNextBin(Form) Export
	
	GoToTheNextBin(Form);
	
EndProcedure

// The procedure is called when you click the "pick up items from other Cells" button on the message to user page,
// after the user has selected the action "move to the next Cell".
// The procedure "includes" an algorithm for selecting products for selection/placement from / in other cells.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SelectGoodsFromOtherBins(Form) Export
	
	If ThisIsLastLineOfScan(Form) Then
		GoToNextScanLine(Form, True);
	Else
		GoToNextScanLine(Form, True);
		SetParametersForScanItems(Form);
		GoToPage3(Form,"ScanPage");
		HandleWarningWhenScanningValue(Form);
	EndIf;
	
EndProcedure

// The procedure is called when you click the "cancel boardingother Cells" button on the message to user page,
// after the user has selected the action "re-order the next scan Line".
// The procedure "disables" the algorithm for selecting products for selection/placement from / in other cells.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure CancelGoodsPickingFromOtherBins(Form) Export
	
	If ThisIsLastLineOfScan(Form) Then
		GoToNextScanLine(Form);
	Else
		GoToNextScanLine(Form);
		SetParametersForScanItems(Form);
		GoToPage3(Form,"ScanPage");
		DisplayTaskState(Form);
	EndIf;
	
EndProcedure

// The procedure is called when you click the "get Goods" button on the message to user page.
// Initializes the algorithm for selecting / placing products in other cells.
// Depending on the result of" getting " products in other cells, the structure of the dialog is formed - the text of the message 
// about the composition of the buttons. Then a dialog message is displayed.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure AddGoods(Form) Export
	
	Parameter_1 = "";
	ContinueHeader = "";
	TitleCompleteTask = "";
	WebServiceMode = Form.WebServiceMode;
	JobType = Form.ModeSettings.JobType;
	CurrentScanningLine = Form.CurrentScanningLine;
	NumberOfCellsInTheTask = Form.CellsForScanning.Count();
	Form.GoodsAreSelected = True;
	
	Buttons = New ValueList;
	AddItemsNotSelectedToTableForScanningItems(Form, True);
	
	If JobType = "Location" Then
		ContinueHeader = NStr("vi = 'Tiếp tục sắp xếp hàng hóa vào ô %1';
								|ru = 'Продолжить размещение товаров в ячейку %1';
								|en = 'Resume put-away to bin %1'; fa = 'Resume put-away to bin %1';
								|it = 'Continuare il collocamento delle merci nella cella %1';
								|pl = 'Kontynuuj umieszczanie towarów w komórce %1';
								|tr = '%1 hücresine ürün yerleştirmeye devam et'");
		TitleCompleteTask = NStr("vi = 'Kết thúc sắp xếp hàng hóa';
								|ru = 'Завершить размещение товаров';
								|en = 'Finish put-away'; fa = 'پایان جای‌گذاری';
								|it = 'Terminare il collocamento delle merci';
								|pl = 'Zakończyć umieszczanie towarów';
								|tr = 'Ürün yerleştirmeyi tamamla'");
	Else
		ContinueHeader = NStr("vi = 'Tiếp tục chọn các mục từ ô %1';
								|ru = 'Продолжить отбор товаров из ячейки %1';
								|en = 'Resume picking items from storage bin %1'; fa = 'Resume picking items from storage bin %1';
								|it = 'Continuare la selezione di merci dalla cella %1';
								|pl = 'Kontynuować wybór towarów z komórki %1';
								|tr = '%1 hücresinden ürünleri seçmeye devam et'");
		TitleCompleteTask = NStr("vi = 'Kết thúc thực hiện nhiệm vụ';
								|ru = 'Завершить выполнение задания';
								|en = 'Finish task'; fa = 'پایان وظیفه';
								|it = 'Completare task';
								|pl = 'Zakończ wykonanie zadania';
								|tr = 'Görevi tamamla'");
	EndIf;
	
	GoToNextCellButton = NewDialogButton("GoToTheNextScanningBin", 
		NStr("vi = 'Chuyển đến ô tiếp theo';
			|ru = 'Перейти к следующей ячейке';
			|en = 'Go to next storage bin'; fa = 'رفتن به محل نگهداری بعدی';
			|it = 'Passare alla cella successiva';
			|pl = 'Przejdź do następnej komórki';
			|tr = 'Sonraki hücreye git'"));
	ContinueButton = NewDialogButton("GoToThePreviousPage", 
		StringFunctionsClientServer.SubstituteParametersToString(ContinueHeader, ?(WebServiceMode, CurrentScanningLine.CellCode,
			CurrentScanningLine.Cell)));
	FinishButton = NewDialogButton("FinishJobExecution", TitleCompleteTask);
	
	If NumberOfCellsInTheTask < Form.CellsForScanning.Count() Then
		
		MessageText = NStr("vi = 'Các ô đã được chọn cho các hàng hóa %1 hơn nữa.';
							|ru = 'Подобраны ячейки для дальнейшего %1 товаров.';
							|en = 'Bins assigned to task: %1.'; fa = 'Bins assigned to task: %1.';
							|it = 'Sono state selezionate le celle per successivo %1 delle merci.';
							|pl = 'Zostały wybrane komórki do dalszego %1 towarów.';
							|tr = 'Daha fazla %1 ürün için seçilen hücreler.'");
		If JobType = "Filter" Then
			Parameter_1 = NStr("vi = 'lọc';
								|ru = 'отбора';
								|en = 'inventory picking'; fa = 'inventory picking';
								|it = 'della selezione';
								|pl = 'filtru';
								|tr = 'filtre'");
		Else
			Parameter_1 = NStr("vi = 'sắp xếp';
								|ru = 'размещения';
								|en = 'inventory put-away'; fa = 'inventory put-away';
								|it = 'di collocamento';
								|pl = 'rozmieszczanie';
								|tr = 'yerleştirme'");
		EndIf;
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Parameter_1);
		
		Buttons.Add(GoToNextCellButton);
		Buttons.Add(FinishButton);
		
		ShowMessageDialog(Form, QueryText, Buttons);
		
	Else
		
		MessageText = NStr("vi = 'Không thể chọn ô cho %1.';
							|ru = 'Не удалось подобрать ячейки для %1.';
							|en = 'Cannot find suitable bins. Task: %1.'; fa = 'Cannot find suitable bins. Task: %1.';
							|it = 'Non è stato possibile selezionare le celle per %1.';
							|pl = 'Nie udało się dobrać komórki dla %1.';
							|tr = '%1 için hücreler seçilmedi.'");
		If JobType = "Filter" Then
			Parameter_1 = NStr("vi = 'lựa chọn hàng hóa không được lựa chọn';
								|ru = 'отбора неотобранных товаров';
								|en = 'picking'; fa = 'picking';
								|it = 'la selezione delle merci non selezionate';
								|pl = 'wyboru nie wybranych towarów';
								|tr = 'seçilmemiş ürünlerin filtresi'");
		Else
			Parameter_1 = NStr("vi = 'vị trí của hàng hóa chưa được sắp xếp';
								|ru = 'размещения неразмещенных товаров';
								|en = 'put-away'; fa = 'put-away';
								|it = 'il collocamento delle merci non collocate';
								|pl = 'umieszczenia nieumieszczonych towarów';
								|tr = 'yerleştirilmemiş ürünlerin yerleştirilmesi'");
		EndIf;
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Parameter_1);
		
		Buttons.Add(ContinueButton);
		Buttons.Add(FinishButton);
		
		ShowMessageDialog(Form, QueryText, Buttons);
		HandleWarningWhenScanningValue(Form);
		
	EndIf;
	
EndProcedure

// Wait handler for the " OK " command on the cell marking page for recalculation.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure AddressSelectionOKWaitHandler(Form) Export
	
	If Form.EnteringBarcodeIsCanceled Then
		Return;
	EndIf;
	
	Object = Form.Object;
	WebServiceMode = Form.WebServiceMode;
	CellBarcode = Form.BarcodeOfTheScanParameter;
	
	CellParameters_ = WorkplaceOfWarehouseWorkerApplicationInterface.FindCellByBarcode(Object.Warehouse,
		Object.Premise, CellBarcode);
	
	If CellParameters_.ReturnCode = 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể đánh dấu ô ""%1"" để kiểm đếm.';
				|ru = 'Не удалось отметить к пересчету ячейку ""%1"".';
				|en = 'Cannot mark bin %1 for physical count.'; fa = 'Cannot mark bin %1 for physical count.';
				|it = 'Non è stato possibile contrassegnare per il ricalcolo la cella ""%1"".';
				|pl = 'Nie udało się oznaczyć komórkę do przeliczenia ""%1"".';
				|tr = 'Yeniden hesaplama için ""%1"" hücresi işaretlenemedi.'"), CellBarcode);
	Else
		WorkplaceOfWarehouseWorkerApplicationInterface.MarkABinForRecount(CellParameters_.Cell);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Ô ""%1"" được đánh dấu để kiểm đếm.';
				|ru = 'Ячейка ""%1"" помечена к пересчету.';
				|en = 'Storage bin %1 is marked for physical count.'; fa = 'Storage bin %1 is marked for physical count.';
				|it = 'La cella ""%1"" contrassegnata per il ricalcolo.';
				|pl = 'Komórka ""%1"" oznaczona do przeliczenia.';
				|tr = '""%1"" hücresi yeniden hesaplama için işaretlendi.'"), ?(WebServiceMode, CellParameters_.CellCode, CellParameters_.Cell));
	EndIf;
	
	GoToPreviousPageButton = NewDialogButton("GoToThePreviousPage", NStr("vi = 'Đồng ý';
																		|ru = 'ОК';
																		|en = 'OK'; fa = 'تأیید';
																		|it = 'OK';
																		|pl = 'OK';
																		|tr = 'Tamam'"), True);
	ShowMessageDialog(Form, MessageText, GoToPreviousPageButton);
	
EndProcedure

// Returns a view of the product series of the warehouse task line.
//
// Parameters:
//	ScanLine - See ScanLine
//
// Returns:
//	String - presentation of the product series of the warehouse task.
//
Function SetSeriesPresentation(ScanLine)
	
	Presentation = NStr("vi = '%BatchNumber%';
						|ru = '%BatchNumber%';
						|en = '%BatchNumber%'; fa = '%BatchNumber%';
						|it = '%BatchNumber%';
						|pl = '%BatchNumber%';
						|tr = '%BatchNumber%'");
	
	If ScanLine.SpecifyNumberWhenRegisteringBatch Then
		BatchNumber = TrimAll(ScanLine.BatchNumber);
	Else
		BatchNumber = "";
	EndIf;
	
	If ScanLine.UseShelfLifeOnBatchRegistration Then
		
		Presentation = NStr("vi = '%BatchNumber% đến %ValidUntil_%';
							|ru = '%BatchNumber% до %ValidUntil_%';
							|en = '%BatchNumber%, shelf life till %ValidUntil_%'; fa = '%BatchNumber%, shelf life till %ValidUntil_%';
							|it = '%BatchNumber% fino a %ValidUntil_%';
							|pl = '%BatchNumber% do %ValidUntil_%';
							|tr = '%ValidUntil_% kadar %BatchNumber%'");
		
		If ScanLine.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
			RowFormat = "DF=MM.yy";
		ElsIf ScanLine.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToDays Then
			RowFormat = "DF=dd.MM.yy; DLF=D";
		Else
			RowFormat = "DF=dd.MM.yy; DLF=DT";
		EndIf;
		
		Presentation = StrReplace(Presentation, "%ValidUntil_%", Format(ScanLine.ValidUntil_, RowFormat));
	EndIf;
	
	Presentation = StrReplace(Presentation, "%BatchNumber%", BatchNumber);
	
	Return TrimAll(Presentation);
	
EndFunction

// Returns the number - the number of task documents available for the warehouse employee to complete.
//
// Parameters:
//	JobType - String - type of warehouse task.
//	Assignees - Array of CatalogRef.Users - list of task performers.
//	Warehouse - CatalogRef.Warehouses - the warehouse for which the number of tasks is returned.
//	Premise - CatalogRef.Warerooms - warehouse premises.
//
// Returns:
//	Number - the number of tasks available for the specified type.
//
Function NumberOfWarehouseTasksToComplete(JobType, Assignees, Warehouse, Premise) Export
	
	Query = New Query;
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Assignees", Assignees);
	
	If JobType = "Filter" 
		Or JobType = "Location" 
		Or JobType = "Move" Then
		
		OperationKind = TypeOfPlacementSelectionOperation(JobType);
		
		Query.SetParameter("OperationKind", OperationKind);
		
		Query.Text = 
		"SELECT
		|	COUNT(*) AS DocumentsCount
		|FROM
		|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
		|WHERE
		|	GoodsPickingPlacement.OperationKind = &OperationKind
		|	AND GoodsPickingPlacement.Posted
		|	AND GoodsPickingPlacement.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.Prepared2)
		|	AND GoodsPickingPlacement.Performer IN(&Assignees)
		|	AND GoodsPickingPlacement.Warehouse = &Warehouse
		|	AND GoodsPickingPlacement.Premise = &Premise";
		
	ElsIf JobType = "Recalculate" Then
		
		Query.Text = 
		"SELECT
		|	COUNT(*) AS DocumentsCount
		|FROM
		|	Document.InventoryRecount AS InventoryRecount
		|WHERE
		|	InventoryRecount.Posted
		|	AND InventoryRecount.Status = VALUE(Enum.InventoryRecountStatuses.Prepared2)
		|	AND InventoryRecount.Performer IN(&Assignees)
		|	AND InventoryRecount.Warehouse = &Warehouse
		|	AND InventoryRecount.Premise = &Premise";
		
	ElsIf JobType = "Receiving" Then
		
		Query.Text = 
		"SELECT
		|	COUNT(*) AS DocumentsCount
		|FROM
		|	Document.GoodsReceiptNote AS GoodsReceiptNote
		|WHERE
		|	GoodsReceiptNote.Posted
		|	AND GoodsReceiptNote.Status = VALUE(Enum.GoodsReceiptNoteStatuses.ToReceive)
		|	AND GoodsReceiptNote.Warehouse = &Warehouse
		|	AND GoodsReceiptNote.Premise = &Premise
		|	AND GoodsReceiptNote.EmployeeResponsible IN(&Assignees)";
		
	ElsIf JobType = "PickingCheck" Then
		
		Query.Text = 
		"SELECT
		|	COUNT(*) AS DocumentsCount
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.Posted
		|	AND GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForChecking)
		|	AND GoodsIssueNote.Warehouse = &Warehouse
		|	AND GoodsIssueNote.Premise = &Premise
		|	AND GoodsIssueNote.Inspector IN(&Assignees)";
		
	EndIf;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.DocumentsCount;
	
EndFunction

// Checks whether the version 8.2 version of the client application interface is installed by the specified is user name.
//
// Parameters:
//	UserName - String - name of the IB user.
//
// Returns:
//	Boolean - True if the interface is version 8.2, otherwise False.
//
Function Version8_2OfClientApplicationInterface(UserName) Export 

	Var InterfaceVersion82;
	
	Settings = SystemSettingsStorage.Load("Common/ClientSettings", "",, UserName);
	
	If Settings = Undefined Then
		                                                               
		InterfaceVersion82 = Not (Metadata.InterfaceCompatibilityMode = Metadata.ObjectProperties.InterfaceCompatibilityMode.Taxi
			Or Metadata.InterfaceCompatibilityMode = Metadata.ObjectProperties.InterfaceCompatibilityMode.TaxiEnableVersion8_2);	
			
	Else
			
		InterfaceVersion82 = (Settings.ClientApplicationInterfaceVariant = ClientApplicationInterfaceVariant.Version8_2)
		
	EndIf;		
	
	Return InterfaceVersion82;
	
EndFunction

// Sets the version 8.2 version of the client application interface for the specified is user name.
//
// Parameters:
//	UserName - String - name of the IB user.
//
Procedure InstallVersion8_2OfClientApplicationInterface(UserName) Export
		
	ClientSettings = New ClientSettings;
	ClientSettings.ClientApplicationInterfaceVariant = ClientApplicationInterfaceVariant.Version8_2;
	ClientSettings.ShowNavigationAndActionsPanels = False;
	ClientSettings.ShowSectionsPanel = True;
	ClientSettings.ApplicationFormsOpenningMode = ApplicationFormsOpenningMode.Tabs;
	
	SystemSettingsStorage.Save("Common/ClientSettings", "", ClientSettings,, UserName);
	
EndProcedure

// Checks whether the previously entered reference series was specified.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Series - See ProductSeries
// 
// Returns:
//	Boolean - True if the entered reference series has not been specified before.
//
Function ReferenceSeriesIsUnique(Form, Series)
	
	ScannedGoods     = Form.ScannedGoods;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	Filter = New Structure("Products, Characteristic, Purpose, Package, Series");
	
	FillPropertyValues(Filter, CurrentScanningLine, , "Series");
	FillPropertyValues(Filter, Series);
	
	RowsArray = ScannedGoods.FindRows(Filter);
	
	If RowsArray.Count() > 0 Then
		Form.ModeSettings.MessageID_ = "ErrorSeriesIsNotUnique";
		Form.ModeSettings.DisplayWarningWhenScanning = True;
		
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Fills in information about the quantity of the scanned product according to the barcode information.
//
// Parameters:
//	OwnGoods - See OwnGoods
//
Procedure FillInProductWeightByBarcode(OwnGoods)
	
	ProductBarcode     = InformationRegisters.ItemsBarcodes.PrepareBarcode(OwnGoods.Barcode);
	BarcodeParameters = New Structure("Barcode, Count", Upper(TrimAll(ProductBarcode)), 1);
	
	WeightBarCodePrefixes = SettingsValueCached.GetWeightBarCodePrefixes();
	InformationRegisters.ItemsBarcodes.ConvertWeightBarcode(BarcodeParameters, WeightBarCodePrefixes);
	
	OwnGoods.QuantityByBarcode = BarcodeParameters.Count;
	
EndProcedure

// Checks whether the product quantity is specified correctly when scanning the barcode.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - True if the quantity is specified correctly.
//
Function BarcodeQuantityIsCorrect(Form)
	
	HasErrors = False;
	
	ModeSettings           = Form.ModeSettings;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	JobType        = ModeSettings.JobType;
	ThisIsSetOfGoods   = ModeSettings.SetOfProducts_;
	SelectionScanned = ModeSettings.SelectionScanned;
	
	If ThisIsSetOfGoods Then
		Return True;
	EndIf;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(ModeSettings.ProcessingProcedure_);
	
	NumberOfPackages              = CurrentScanningLine.NumberOfPackages;
	NumberOfPackagesInDocument    = CurrentScanningLine.NumberOfPackagesInDocument;
	NumberOfPackagingsScanned = CurrentScanningLine.NumberOfPackagingsScanned;
	QuantityByBarcode           = CurrentScanningLine.QuantityByBarcode;
	
	DimensionalUnitsOfMeasurement = DimensionalUnitsOfMeasurement();
	ThisIsMeasuredCommodity = DimensionalUnitsOfMeasurement.Find(CurrentScanningLine.MeasuredValueType) <> Undefined;
	
	PermissibleDeviationOfSelectedGoods = Form.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving;
	MaximumQuantityOfSelectedGoods_ = NumberOfPackages + NumberOfPackages *
		PermissibleDeviationOfSelectedGoods / 100;
	
	If JobType = "Location" Then
		If (NumberOfPackagingsScanned + QuantityByBarcode) > NumberOfPackagesInDocument Then
			HasErrors = True;
		EndIf;
	ElsIf JobType = "Move" Then
		If SelectionScanned
			And ThisIsProcessingOrderOfItemCell Then
			
			If NumberOfPackagingsScanned + QuantityByBarcode > NumberOfPackagesInDocument Then
				HasErrors = True;
			EndIf;
			
		Else
			If NumberOfPackagingsScanned + QuantityByBarcode > CurrentScanningLine.NumberOfPackages Then
				HasErrors = True;
			Else
				If SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus) 
					And QuantityByBarcode < NumberOfPackagingsScanned Then
					
					Filter = New Structure("Cell, Products, Characteristic, Purpose, Package");
					FillPropertyValues(Filter, CurrentScanningLine);
					
					RowsArray = Form.ScannedGoods.FindRows(Filter);
					
					BatchNumber = RowsArray[0].BatchNumber;
					ValidUntil_ = RowsArray[0].ValidUntil_;
					NumberOfDifferentSeries = 1;
					
					For Each String In RowsArray Do
						If CurrentScanningLine.SpecifyNumberWhenRegisteringBatch
							And CurrentScanningLine.UseShelfLifeOnBatchRegistration Then
							
							If String.BatchNumber <> BatchNumber
								And String.ValidUntil_ <> ValidUntil_ Then
								
								NumberOfDifferentSeries = 2;
								Break;
								
							EndIf;
							
						Else
							If String.BatchNumber <> BatchNumber
								Or String.ValidUntil_ <> ValidUntil_ Then
								
								NumberOfDifferentSeries = 2;
								Break;
								
							EndIf;
						EndIf;
					EndDo;
					
					If NumberOfDifferentSeries > 1 Then
						HasErrors = True;
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
	ElsIf JobType = "Filter" Then
		If (ThisIsMeasuredCommodity
				And NumberOfPackagingsScanned + QuantityByBarcode > MaximumQuantityOfSelectedGoods_)
			Or (Not ThisIsMeasuredCommodity
				And NumberOfPackagingsScanned + QuantityByBarcode > NumberOfPackages) Then
			
			HasErrors = True;
			
		Else
			If SeriesAreIndicatedUponSelection(CurrentScanningLine.BatchesIndicationStatus)
				And QuantityByBarcode < NumberOfPackagingsScanned Then
				
				Filter = New Structure("Cell, Products, Characteristic, Purpose, Package");
				FillPropertyValues(Filter, CurrentScanningLine);
				
				RowsArray = Form.ScannedGoods.FindRows(Filter);
				
				BatchNumber = RowsArray[0].BatchNumber;
				ValidUntil_ = RowsArray[0].ValidUntil_;
				NumberOfDifferentSeries = 1;
				
				For Each String In RowsArray Do
					If CurrentScanningLine.SpecifyNumberWhenRegisteringBatch
						And CurrentScanningLine.UseShelfLifeOnBatchRegistration Then
						
						If String.BatchNumber <> BatchNumber
							And String.ValidUntil_ <> ValidUntil_ Then
							
							NumberOfDifferentSeries = 2;
							Break;
							
						EndIf;
						
					Else
						If String.BatchNumber <> BatchNumber
							Or String.ValidUntil_ <> ValidUntil_ Then
							
							NumberOfDifferentSeries = 2;
							Break;
							
						EndIf;
					EndIf;
				EndDo;
				
				If NumberOfDifferentSeries > 1 Then
					HasErrors = True;
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
	If HasErrors Then
		Form.ModeSettings.MessageID_ = "ErrorQuantityGreaterThanRequired";
		Form.ModeSettings.DisplayWarningWhenScanning = True;
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether the product is a barcode.
//
// Parameters:
//	Barcode - String - the scanned barcode.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
// Returns:
//	Boolean - True if it is the barcode of the product.
//
Function ThisIsProductBarcode(Barcode, OwnGoods = Undefined)
	
	OwnGoods = WorkplaceOfWarehouseWorkerApplicationInterface.FindProductOrPackingList(Barcode, False);
	
	If OwnGoods.ReturnCode = 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether the barcode is the packing list.
//
// Parameters:
//	Barcode - String - the scanned barcode.
//	ExpirationDate_ - String, Undefined - expiration date of the product series.
//	OwnGoods - See WorkplaceOfWarehouseWorkerServer.OwnGoods
//
// Returns:
//	Boolean - True if it is the barcode of the packing list.
//
Function ThisIsBarcodeOfPackingList(Barcode, ExpirationDate_, OwnGoods = Undefined)
	
	If ValueIsFilled(ExpirationDate_) Then
		Return False;
	EndIf;
	
	If ValueIsFilled(OwnGoods)
		And ValueIsFilled(OwnGoods.PackingList) Then
		
		Return True;
		
	EndIf;
	
	OwnGoods = WorkplaceOfWarehouseWorkerApplicationInterface.FindProductOrPackingList(Barcode, True);
	
	If OwnGoods.ReturnCode = 0
		Or Not ValueIsFilled(OwnGoods.PackingList) Then
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether the barcode is a series.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	BatchNumber - String - the serial number of the scanned product.
//	SeriesShelfLife - String,Undefined - expiration date of the product series.
//
// Returns:
//	Boolean - True if it is a barcode of the series.
//
Function ThisIsBarcodeOfSeries(Form, BatchNumber, SeriesShelfLife)
	
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If Not ValueIsFilled(CurrentScanningLine.SKProducts) Then
		Return False;
	EndIf;
	
	If Not SeriesAreSpecified(CurrentScanningLine.BatchesIndicationStatus) Then
		Return False;
	EndIf;
	
	ThisIsScan = Form.ModeSettings.Mode = "EnterValue";
	
	SeriesIndicationParameters = New Structure("SpecifyNumberWhenRegisteringBatch, UseShelfLifeOnBatchRegistration,
		|PrecisionOfBatchShelfLifeIndication");
	FillPropertyValues(SeriesIndicationParameters, CurrentScanningLine);
	
	SeriesParameters = WorkplaceOfWarehouseWorkerApplicationInterface.FindSeries_(BatchNumber, SeriesShelfLife,
		CurrentScanningLine.ProductKind, SeriesIndicationParameters, ThisIsScan);
	
	If SeriesParameters.ReturnCode = 0 Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Checks whether the scan line is the last one and displays a dialog box.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	Cancel - Boolean - True if the last row of the warehouse task to be scanned is the last one.
//
Procedure BeforeMovingOnToNextScanLine(Form, Cancel)
	
	Var ActionType, ExecutionType;
	
	WebServiceMode = Form.WebServiceMode;
	ModeSettings = Form.ModeSettings;
	JobType = ModeSettings.JobType;
	SelectionScanned = Form.ModeSettings.SelectionScanned;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	If ThisIsLastLineOfScan(Form) Then
		
		Cancel = True;
		
		GetActionType(JobType, ActionType, ExecutionType);
		TaskTypePresentation = Lower(ModeSettings.JobType);
		GoodsPresentation = ?(WebServiceMode,
			GoodsPresentation(CurrentScanningLine.ItemName, CurrentScanningLine.ItemVariantName),
			GoodsPresentation(CurrentScanningLine.Products, CurrentScanningLine.Characteristic));
		
		ReplacementParameters = New Structure;
		
		ReplacementParameters.Insert("OwnGoods", GoodsPresentation);
		ReplacementParameters.Insert("Cell",
			?(WebServiceMode, CurrentScanningLine.CellCode, CurrentScanningLine.Cell));
		ReplacementParameters.Insert("JobType", TaskTypePresentation);
		ReplacementParameters.Insert("ExecutionType", ExecutionType);
		
		QueryText = StringFunctionsClientServer.InsertParametersIntoString(
			NStr("vi = 'Hàng hóa""[OwnGoods]"" trong ô ""[Cell]"" là cuối cùng trong nhiệm vụ [JobType]. 
				|Kết thúc thực hiện [ExecutionType] hàng hóa?';
				|ru = 'Товар ""[OwnGoods]"" в ячейке ""[Cell]"" последний в задании на [JobType]. 
				|Завершить выполнение [ExecutionType] товаров?';
				|en = '[ExecutionType] [JobType]. [OwnGoods] in bin [Cell] is the last item in this task.
				|Do you want to finish the task?'; fa = '[ExecutionType] [JobType]. [OwnGoods] in bin [Cell] is the last item in this task.
				|Do you want to finish the task?';
				|it = 'La merce ""[OwnGoods]"" nella cella ""[Cell]"" è l''ultima nel task di [JobType]. 
				| Completare il task di [ExecutionType] delle merci?';
				|pl = 'Towar ""[OwnGoods]"" w komórce ""[Cell]"" ostatni w zadaniu na [JobType].
				|Zakończyć wykonanie[ExecutionType] towarów?';
				|tr = '""[Cell]"" hücresindeki ""[OwnGoods]"" ürün, [JobType]''ndeki görevin sonuncusudur. 
				| [ExecutionType] ürünlerin gerçekleştirilmesini tamamla?'"),
			ReplacementParameters);
		
		FinishButton = NewDialogButton("FinishJobExecution",
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Kết thúc %1 hàng hóa';
																			|ru = 'Завершить %1 товаров';
																			|en = 'Finish task: %1'; fa = 'Finish task: %1';
																			|it = 'Terminare %1 delle merci';
																			|pl = 'Zakończyć %1 towarów';
																			|tr = '%1 ürünü tamamla'"), ActionType), True);
		ContinueButton = NewDialogButton("GoToScanning",
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tiếp tục %1 hàng hóa';
																			|ru = 'Продолжить %1 товаров';
																			|en = 'Resume task: %1'; fa = 'Resume task: %1';
																			|it = 'Continuare %1 delle merci';
																			|pl = 'Kontynuować %1 towarów';
																			|tr = '%1 ürünleri devam et'"), ActionType));
		
		Buttons = New ValueList;
		Buttons.Add(FinishButton);
		
		If (JobType = "Filter"
			Or JobType = "Location"
			Or JobType = "Move"
				And SelectionScanned)
			And (CurrentScanningLine.NumberOfPackagingsScanned = CurrentScanningLine.NumberOfPackages) Then
			
		Else
			Buttons.Add(ContinueButton);
		EndIf;
		
		If JobType = "Move" Then
			If SelectionScanned Then
				ShowMessageDialog(Form, QueryText, Buttons);
			Else
				WhenCurJobScanIsComplete(Form);
			EndIf;
		Else
			ShowMessageDialog(Form, QueryText, Buttons);
		EndIf;
		
	EndIf;
	
EndProcedure

// Called when you go to the next product scan line. Depending on
// the task type and progress status, a dialog message is displayed or you can skip to
// the next scan line.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	AddGoods - Boolean - True, a sign that the product must be selected from another storage cell.
//
Procedure GoToNextScanLine(Form, AddGoods = False)
	
	Cancel = False;
	
	BeforeMovingOnToNextScanLine(Form, Cancel);
	
	If Not Cancel Then
		GoToNextScanLineOfJob(Form, AddGoods);
	EndIf;
	
EndProcedure

// Returns an indication that the item is the last item in the cell.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Boolean - True if the scanned item line is the last one in the cell according to the warehouse task.
//
Function ThisIsLastItemInCell(Form)
	
	JobType = Form.ModeSettings.JobType;
	GoodsForScanning = Form.GoodsForScanning;
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	CurrentScanningLine = Form.CurrentScanningLine;
	
	ThisIsProcessingOrderOfItemCell = ThisIsProcessingOrderOfItemCell(Form.ModeSettings.ProcessingProcedure_);
	
	If CurrentScanningLine = Undefined Then
		Return False;
	EndIf;
	
	If ThisIsSetOfGoods
		Or JobType = "Recalculate"
		Or JobType = "PickingCheck"
		Or ThisIsProcessingOrderOfItemCell Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(CurrentScanningLine.SKProducts) Then
		Filter = New Structure("Cell, Products, Characteristic, Purpose, Package");
		FillPropertyValues(Filter, CurrentScanningLine);
		
		RowsArray = GoodsForScanning.FindRows(Filter);
		LineNumber = RowsArray.Count() - 1;
		LineOfProductList = RowsArray[LineNumber];
		
		ThisIsLastOne = (LineOfProductList.QuantityOfGoodsInABin = LineOfProductList.GoodsNumberInTheBin);
		Return ThisIsLastOne;
	Else
		ThisIsLastOne = (CurrentScanningLine.QuantityOfGoodsInABin = CurrentScanningLine.GoodsNumberInTheBin);
		Return ThisIsLastOne;
	EndIf;
	
EndFunction

// Puts the system in the waiting state for product barcode scanning.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SwitchToProductScanStandbyMode(Form)
	
	ResetSignsOfScanningAllParameters(Form);
	SetParameterScanFlag(Form, "Products", True);
	
	Form.CurrentScanningLine = ScanLine();
	
EndProcedure

// Checks whether the product series is specified in the warehouse task line.
//
// Parameters:
//	JobType - String - type of warehouse task.
//	ScanLine - See ScanLine
//
// Returns:
//	Boolean - True if the product series is specified.
//
Function SeriesIsFilled(JobType, ScanLine)
	
	If (JobType = "Filter"
			Or JobType = "Move")
		And SeriesAreIndicatedUponSelection(ScanLine.BatchesIndicationStatus) Then
		
		If ValueIsFilled(ScanLine.BatchNumber)
			Or ValueIsFilled(ScanLine.ValidUntil_) Then
			
			Return True;
			
		Else
			Return False;
		EndIf;
		
	ElsIf ValueIsFilled(ScanLine.Series) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Sets the button display parameters as "Pressed"or" Not pressed".
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//	TagName - String - element name.
//	Mode - String - mode ID, can take the values: "Pressed", "not Pressed".
//
Procedure SetButtonDisplayParameters(Form, TagName, Mode)
	
	Item = Form.Items[TagName];
	
	If Mode = "Clicked" Then
		HighlightElement(Form.ScreenResolution, Item);
	ElsIf Mode = "NotClicked" Then
		RemoveElementIllumination(Item);
	EndIf;
	
EndProcedure

// Sets parameters for buttons that control the order in which a warehouse task is processed.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetParametersForItemsInWarehouseTaskProcessingOrder(Form)
	
	ModeSettings = Form.ModeSettings;
	
	If ModeSettings = Undefined Then
		ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.StorageBinGoods;
	Else
		ProcessingProcedure_ = ModeSettings.ProcessingProcedure_;
	EndIf;
	
	If ProcessingProcedure_ = Enums.WarehouseJobProcessingProcedure.GoodsBin Then
		SetButtonDisplayParameters(Form, "ServiceProcessingProcedureGoodsBin", "Clicked");
		SetButtonDisplayParameters(Form, "ServiceProcessingProcedureBinGoods", "NotClicked");
	Else
		SetButtonDisplayParameters(Form, "ServiceProcessingProcedureGoodsBin", "NotClicked");
		SetButtonDisplayParameters(Form, "ServiceProcessingProcedureBinGoods", "Clicked");
	EndIf;
	
EndProcedure

// Sets the visibility of the line with information about the number of product packages
// in the task line.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetVisibilityOfQuantityInDocument(Form)
	
	Items = Form.Items;
	
	VisibilityStakeDoc = DisplayScanItem(Form, "QuantityOfGoodsInDocument");
	
	Items.EmptyQuantityLabelInTheDocument.Visible = VisibilityStakeDoc;
	Items.GroupQuantityInTheDocument.Visible        = VisibilityStakeDoc;
	
EndProcedure

// Sets the availability of commands to change the scan scheme.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the warehouse worker's workplace, which contains:
//		* Items - FormAllItems - elements of the Form of the warehouse worker's workplace that contain:
//			** ServiceTSTSeriesScanMode -FormButton - sets the order of execution of the warehouse task
//																for placing goods (first the product is scanned
//																, then the product series, then the product again).
//			** ServiceTBTSeriesScanMode -FormButton - sets the order of execution of the warehouse task
//																for placing goods (first the product is scanned, then
//																all product series).
//
Procedure SetAvailabilityOfScanSchemeChange(Form)
	
	AvailabilityOfScanSchemeChanges = ChangingSeriesScanSchemeIsAvailable(Form);
	
	Form.Items.ServiceTSTSeriesScanMode.Enabled = AvailabilityOfScanSchemeChanges;
	Form.Items.ServiceTBTSeriesScanMode.Enabled = AvailabilityOfScanSchemeChanges;
	
EndProcedure

// Sets the availability of commands to change the crawl order.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure SetVisibilityToChangeCrawlOrder(Form)
	
	ThisIsSetOfGoods = Form.ModeSettings.SetOfProducts_;
	IsFilter = (Form.ModeSettings.JobType = "Filter");
	ThisIsAcceptance = (Form.ModeSettings.JobType = "Receiving");
	ThisIs_Recalculation = (Form.ModeSettings.JobType = "Recalculate");
	ThisIsPlacement = (Form.ModeSettings.JobType = "Location");
	ItIsTransfer = (Form.ModeSettings.JobType = "Move");
	ThisIsSelectionCheck = (Form.ModeSettings.JobType = "PickingCheck");
	
	// Availability of bypass order settings.
	AvailabilityOfCrawlOrderSettings = ChangingTraversalOrderIsAvailable(Form);
	
	Form.Items.ServiceProcessingProcedureBinGoods.Enabled = AvailabilityOfCrawlOrderSettings;
	Form.Items.ServiceProcessingProcedureGoodsBin.Enabled = AvailabilityOfCrawlOrderSettings;
	
	// Visibility of the crawl order settings.
	VisibilityOfCrawlOrderSettings = Not (ThisIsSelectionCheck Or (ThisIsPlacement And ThisIsSetOfGoods) Or ThisIsAcceptance
		Or IsFilter Or ThisIs_Recalculation);
	
	// In a move task, the visibility of changing the traversal order is only available at the placement stage.
	If ItIsTransfer Then
		If Form.ModeSettings.SelectionScanned Then
			VisibilityOfCrawlOrderSettings = True
		Else
			VisibilityOfCrawlOrderSettings = False;
		EndIf;
	EndIf;
	
	Form.Items.ServiceProcessingProcedureBinGoods.Visible = VisibilityOfCrawlOrderSettings;
	Form.Items.ServiceProcessingProcedureGoodsBin.Visible = VisibilityOfCrawlOrderSettings;
	Form.Items.GroupWarehouseTaskProcessingOrder.Visible = VisibilityOfCrawlOrderSettings;
	
EndProcedure

// Returns the number of rows of the container that was scanned.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
// Returns:
//	Number - the number of lines of the scanned container.
//
Function NumberOfRowsOfScannedContainers(Form)
	
	DZScannedContainer = Form.FormAttributeToValue("ScannedPackage");
	
	PackageTable = New ValueTable;
	PackageTable.Columns.Add("Products");
	PackageTable.Columns.Add("Characteristic");
	
	For Each RowOfProduct In DZScannedContainer.Rows Do
		For Each TareString In RowOfProduct.Rows Do
			If TareString.NumberOfPackagingsScanned > 0 Then
				NewRow = PackageTable.Add();
				FillPropertyValues(NewRow, TareString);
			EndIf;
		EndDo;
	EndDo;
	
	PackageTable.GroupBy("Products, Characteristic");
	
	Return PackageTable.Count();
	
EndFunction

// Initializes the table part of the product acceptance and shipment zones.
//
// Parameters:
//	Form - ClientApplicationForm - form of the warehouse employee's workplace.
//
Procedure FillInShipmentAcceptanceZones(Form)
	
	Warehouse = Form.Object.Warehouse;
	WebServiceMode = Form.WebServiceMode;
	Premise = Form.Object.Premise;
	ReceivingShippingAreas = Form.ReceivingShippingAreas;
	
	If WebServiceMode Then
		ReceivingShippingAreas.Load(WorkplaceOfWarehouseWorkerXDTO.ReceivingShippingAreas(Form));
	Else
		ReceivingShippingAreas.Load(WorkplaceOfWarehouseWorkerApplicationInterface.ReceivingShippingAreas(Warehouse, Premise));
	EndIf;
	
EndProcedure

// Checks the usage setting of the series.
//
// Parameters:
//	ScanLine - See ScanLine
//
// Returns:
//	Boolean - True if the series identifies a product instance.
//
Function SeriesIdentifiesItemInstance(ScanLine)
	
	ConfiguringSeriesUsage = Common.ObjectAttributeValue(ScanLine.ProductKind,
		"BatchUsageSettings");
	
	Return ConfiguringSeriesUsage = Enums.ItemsBatchUsageSettings.InventoryItem;
	
EndFunction

// Returns an array whose elements are values of dimensional types of measured values.
//
// Returns:
//	Array of EnumRef.TypesOfMeasuredValues - the elements are the values of the dimensional types of the measured quantities.
//
Function DimensionalUnitsOfMeasurement()
	
	DimensionalUnitsOfMeasurement = New Array;
	DimensionalUnitsOfMeasurement.Add(Enums.TypesOfMeasuredValues.Weight);
	DimensionalUnitsOfMeasurement.Add(Enums.TypesOfMeasuredValues.VolumeM3);
	DimensionalUnitsOfMeasurement.Add(Enums.TypesOfMeasuredValues.Length);
	DimensionalUnitsOfMeasurement.Add(Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
	
	Return DimensionalUnitsOfMeasurement;
	
EndFunction

#EndRegion
