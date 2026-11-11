
#Region Variables

&AtClient
Var IdleHandlerParameters;
&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	UpdateServerReflectionBanDate();
	
	PeriodType = Enums.AvailableReportPeriods.Year;
	BeginOfPeriod = BegOfYear(CurrentSessionDate());
	EndOfPeriod = EndOfYear(CurrentSessionDate());
	
	CommonClientServer.SetFilterItem(ReportKindList.Filter, "ReportingSet", 0, DataCompositionComparisonType.Equal,, True);
	CommonClientServer.SetFilterItem(CopyList.Filter, "ReportKind", 0, DataCompositionComparisonType.Equal,, True);

	FileIB = Common.FileInfobase();
	
	// StandardSubsystems.AttachableCommands
	TypesList = ListOfSets.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.GroupSequenceChange;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	#If WebClient Then
		Items.CompareInstancesButton.Title = NStr("vi = 'So sánh các trường hợp (Thin Client)';
													|ru = 'Сравнить экземпляры (Тонкий клиент)';
													|en = 'Compare copies (Thin client)'; fa = 'Compare copies (Thin client)';
													|it = 'Confrontare esemplari (Thin client)';
													|pl = 'Porównaj egzemplarze (Cienki klient)';
													|tr = 'Örnekleri karşılaştır (İnce istemci)'");
		Items.CompareInstancesButton.Enabled = False;
	#EndIf
	
	ClearMessages();
	If Not UpgradeOfMFPFacilitiesHasBeenCompleted() Then
		CommonClient.MessageToUser(
			NStr("vi = 'Không thể lập bộ báo cáo bởi vì chưa thực hiện cập nhật các đối tượng kế toán quốc tế. Hãy thử lại sau.';
				|ru = 'Формирование комплектов отчетов невозможно т.к. не завершено обновление объектов международного учета. Попробуйте позже.';
				|en = 'Cannot generate report sets as the update of financial accounting objects is not completed. Try again later.'; fa = 'Cannot generate report sets as the update of financial accounting objects is not completed. Try again later.';
				|it = 'Impossibile generare il pacchetto di report in quanto l''aggiornamento di oggetti di contabilità internazionale non è stato completato. Riprovare più tardi.';
				|pl = 'Tworzenie zestawów raportów jest niemożliwe, ponieważ nie zakończono aktualizacji obiektów ewidencji międzynarodowej. Spróbuj ponownie.';
				|tr = 'Uluslararası muhasebe nesnelerinin güncellenmesi tamamlanmadığı için rapor setlerinin oluşturulması mümkün değildir. Daha sonra deneyin.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangedDateWhenTransactionsWereBanned" Then
		UpdateServerReflectionBanDate();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportingSetStatusOnChange(Item)
	
	CommonClientServer.SetFilterItem(ListOfSets.Filter, "Status", ReportingSetStatus, DataCompositionComparisonType.Equal,, ValueIsFilled(ReportingSetStatus));
	
EndProcedure

#EndRegion

#Region PackageListEventHandlers

&AtClient
Procedure ListOfSetsOnActivateRow(Item)
	
	ThisForm.AttachIdleHandler("ListOfSetsWhenActivatingWaitHandlerLine", 0.1, True);
	
EndProcedure

#EndRegion

#Region EventHandlersForListOfReportTypes

&AtClient
Procedure ReportKindListOnActivateRow(Item)
	
	ThisForm.AttachIdleHandler("ListOfReportTypesWhenWaitHandlerLineIsActivated", 0.1, True);
	
EndProcedure

#EndRegion

#Region InstanceListEventHandlers

&AtClient
Procedure CopyListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	CurrentData = Items.ReportKindList.CurrentData;
	If CurrentData <> Undefined Then
		GenerateReports(CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyListOnActivateRow(Item)
	
	#If Not WebClient Then
	Items.CompareInstancesButton.Enabled = Items.CopyList.SelectedRows.Count() > 1;
	#EndIf
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ReportTypeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("Key", RowSelected);
	FormParameters.Insert("ReportingSet", Items.ListOfSets.CurrentData.Ref);
	OpenForm("Catalog.FinancialReportTypes.Form.ItemForm",FormParameters);
	
EndProcedure

&AtClient
Procedure CreateSet(Command)
	
	CurrentData = Items.ListOfSets.CurrentData;
	If CurrentData <> Undefined Then
		GenerateReports(CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure CompareCopies(Command)
	
	#If Not WebClient Then
		ComparisonReports = ReportsForComparison(); 
		If ComparisonReports <> Undefined Then
			
			SpreadsheetDocuments = New Structure("Left_1, Right", ComparisonReports[0].Result, ComparisonReports[1].Result);
			SpreadsheetDocumentsAddress = PutToTempStorage(SpreadsheetDocuments, UUID);
			
			Report1 = ComparisonReports[0]; // See NewDescriptionOfOTET
			Report2 = ComparisonReports[1]; // See NewDescriptionOfOTET
			FormOpenParameters = New Structure("SpreadsheetDocumentsAddress, TitleLeft, TitleRight", 
				SpreadsheetDocumentsAddress, Report1.Title, Report2.Title);
			
			OpenForm("CommonForm.CompareSpreadsheetDocuments",
				FormOpenParameters, ThisForm, New UUID);
			
		EndIf;
	#EndIf
	
EndProcedure

&AtServer
Function ReportsForComparison()
	
	If Items.CopyList.SelectedRows.Count() < 2 Then
		Return Undefined;
	EndIf;
	
	ComparisonReports = New Array;
	For IndexOf = 0 To 1 Do
		
		Instance = Items.CopyList.SelectedRows[IndexOf];
		ResultStorage = GeneralPurposeTMServerCall.ObjectAttributeValue(Instance,"ReportResult"); //ValueStorage
		ReportResult = ResultStorage.Get();
		If ReportResult = Undefined Then
			Return Undefined;
		EndIf;
		
		DescriptionOfReport = NewDescriptionOfOTET();
		DescriptionOfReport.Result = PutToTempStorage(ReportResult, UUID);
		DescriptionOfReport.Title = String(Instance);
		
		ComparisonReports.Add(DescriptionOfReport);
		
	EndDo;
	Return ComparisonReports;
	
EndFunction

&AtClient
Procedure SetClosingDate(Command)
	
	OpenForm("InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration.Form.ClosingDatesOfAccountingPostingGeneration", , ThisForm);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListOfSets);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListOfSets, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, ListOfSets.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#Region IdleHandlers

&AtClient
Procedure ListOfSetsWhenActivatingWaitHandlerLine()
	
	CurKit = Items.ListOfSets.CurrentRow;
	CommonClientServer.SetFilterItem(ReportKindList.Filter, "ReportingSet", CurKit, DataCompositionComparisonType.Equal,, True);
	
	CurReportView = Items.ReportKindList.CurrentRow;
	CommonClientServer.SetFilterItem(CopyList.Filter, "ReportingSet", CurKit, DataCompositionComparisonType.Equal,, True);
	CommonClientServer.SetFilterItem(CopyList.Filter, "ReportKind", CurReportView, DataCompositionComparisonType.Equal,, True);
	
EndProcedure

&AtClient
Procedure ListOfReportTypesWhenWaitHandlerLineIsActivated()
	
	CurReportView = Items.ReportKindList.CurrentRow;
	CommonClientServer.SetFilterItem(CopyList.Filter, "ReportKind", CurReportView, DataCompositionComparisonType.Equal,, True);
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidityPeriodStart.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidityPeriodEnd.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportInstances.BeginOfPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportInstances.PeriodEnding");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Format", "L=ru; DLF=D");

EndProcedure

#Region Other

&AtClient
Procedure GenerateReports(ObjectReference)
	
	FormParameters = New Structure("InstanceParameters", ReportGenerationParameters(ObjectReference));
	ReportGenerator = New CallbackDescription("GenerateReportsCompletion", ThisForm, ObjectReference);
	OpenForm("Catalog.FinancialReportSets.Form.ReportParameterForm", FormParameters, ThisForm,,,,ReportGenerator);
	
EndProcedure

&AtServer
Function ReportGenerationParameters(ObjectReference)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfAccountPlans.ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	Catalog.FinancialReportSets.ChartsOfAccounts AS TableOfAccountPlans
	|WHERE
	|	TableOfAccountPlans.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfAccountPlans.ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	Catalog.FinancialReportTypes.ChartsOfAccounts AS TableOfAccountPlans
	|WHERE
	|	TableOfAccountPlans.Ref = &Ref";
	Query.SetParameter("Ref", ObjectReference);
	SetAccountPlans = Query.Execute().Unload().UnloadColumn("ChartOfAccounts");
	
	InstanceParameters = InternationalReportingClientServer.NewReportGenerationParameters();
	InstanceParameters.Resource = "Sum";
	InstanceParameters.ChartsOfAccounts = SetAccountPlans;
	InstanceParameters.OpenForms = TypeOf(ObjectReference) = Type("CatalogRef.FinancialReportSets");
	
	FillPropertyValues(InstanceParameters, ThisForm,,"OpenForms");
	
	Return InstanceParameters; 
	
EndFunction

&AtClient
Procedure GenerateReportsCompletion(InstanceParameters, SetOfReports) Export
	
	If InstanceParameters = Undefined
		Or InstanceParameters = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	FillPropertyValues(ThisForm, InstanceParameters);
	
	CreateInBackgroundJobOnServer(SetOfReports);
	AttachIdleHandler("Attachable_CheckTaskCompletion", 0.1, True);
	
EndProcedure

&AtServer
Procedure CreateInBackgroundJobOnServer(SetOfReports)
	
	CancelJobExecution(JobID);
	
	JobDescription = NStr("vi = 'Tạo bộ báo cáo';
							|ru = 'Создание комплектов отчетов';
							|en = 'Reports sets creation'; fa = 'Reports sets creation';
							|it = 'Creazione di set di report';
							|pl = 'Utworzenie kompletów raportów';
							|tr = 'Raporların setlerinin oluşturulması'");
	ProcedureName        = "InternationalReportingServer.GenerateSetOfReports";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	MethodParameters = PrepareInstanceParameters(SetOfReports);;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, MethodParameters, ExecutionParameters);
	If TimeConsumingOperation.Status = "Error" Then
		Raise TimeConsumingOperation.BriefErrorDescription;
	EndIf;
	
	JobID = TimeConsumingOperation.JobID;

EndProcedure

&AtServer
Function PrepareInstanceParameters(SetOfReports)
	
	If TypeOf(SetOfReports) = Type("CatalogRef.FinancialReportSets") Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	ReportsKinds.FinancialReportType AS FinancialReportType
		|FROM
		|	Catalog.FinancialReportSets.ReportsKinds AS ReportsKinds
		|WHERE
		|	ReportsKinds.Ref = &Ref";
		
		Query.SetParameter("Ref", SetOfReports);
		ReportsKinds = Common.UnloadColumn(Query.Execute().Unload(), "FinancialReportType");
		
	Else
		ReportsKinds = New Array;
		ReportsKinds.Add(SetOfReports);
	EndIf;
	
	CurKit = Items.ListOfSets.CurrentRow;
	InstanceParameters = New Structure;
	InstanceParameters.Insert("MainStorageID", UUID);
	InstanceParameters.Insert("ReportingSet", CurKit);
	InstanceParameters.Insert("ReportsKinds", ReportsKinds);
	InstanceParameters.Insert("SetOfReports", SetOfReports);
	
	ReportInstances = New Map;
	For Each ReportKind In ReportsKinds Do
		Address = PutToTempStorage(Undefined, UUID);
		ReportInstances.Insert(ReportKind, Address);
	EndDo;
	InstanceParameters.Insert("ReportInstances", ReportInstances);
	
	ReportPeriod = New Structure("BeginOfPeriod, EndOfPeriod");
	ReportPeriod.BeginOfPeriod = BeginOfPeriod;
	ReportPeriod.EndOfPeriod = EndOfPeriod;
	InstanceParameters.Insert("ReportPeriod", ReportPeriod);
	
	Filter = New Structure;
	Filter.Insert("Organization", Organization);
	Filter.Insert("Department", Department);
	Filter.Insert("LineOfBusiness", LineOfBusiness);
	InstanceParameters.Insert("Filter", Filter);
	
	InstanceParameters.Insert("ReportKind", Undefined);
	InstanceParameters.Insert("ReportResult", Undefined);
	InstanceParameters.Insert("Resource", Resource);
	InstanceParameters.Insert("Currency", Currency);
	InstanceParameters.Insert("DisplayRowCode", False);
	InstanceParameters.Insert("DisplayNoteInReport", False);
	InstanceParameters.Insert("RowCodeHeader", "");
	InstanceParameters.Insert("CommentHeader", "");
	InstanceParameters.Insert("ReportLanguage", "");
	InstanceParameters.Insert("MultiplierOfAmounts", MultiplierOfAmounts);
	InstanceParameters.Insert("OpenForms", OpenForms);
	InstanceParameters.Insert("DateReportWasGenerated", CurrentSessionDate());
	
	Return InstanceParameters;
	
EndFunction

&AtClient
Procedure CreateCompletionKit(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		CreationResult = GetFromTempStorage(Result.ResultAddress);
		If CreationResult <> Undefined 
			And (TypeOf(CreationResult.SetOfReports) = Type("CatalogRef.FinancialReportTypes")
				Or CreationResult.OpenForms) Then
			
			For Each Instance In CreationResult.InstanceData Do
				FormParameters = New Structure("StorageAddress, GenerateReport", Instance.Key, False);
				FormParameters.Insert("UserSettings", Instance.Value);
				OpenForm("Report.FinancialReport.Form.ReportForm", FormParameters, ThisForm, True);
			EndDo;
			
		EndIf;
	EndIf;
	
	Items.CopyList.Refresh();
	
EndProcedure

&AtClient
Procedure ListOfSetsOnChange(Item)
	
	Items.ReportKindList.Refresh();
	
EndProcedure

&AtServer
Procedure UpdateServerReflectionBanDate()
	
	PeriodEndClosingDate = FinancialAccountingOfGeneralPurpose.ClosingDateOfPostingGeneration();
	Items.SetClosingDate.Title = FinancialAccountingOfGeneralPurpose.PresentationOfCommandToSetBanDate(PeriodEndClosingDate);
	
EndProcedure

// Returns:
// 	Structure - LongDesc:
// * Title - String -  
// * Result - String - 
&AtServer
Function NewDescriptionOfOTET()
	
	Return New Structure("Title,Result");
	
EndFunction

#Region MaintenanceOfLongOperations

&AtClient
Procedure Attachable_CheckTaskCompletion()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	If ValueIsFilled(JobID) Then 
		CallbackOnCompletion = New CallbackDescription("CreateCompletionKit", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelJobExecution(JobID)
	
	If ValueIsFilled(JobID) Then
		TimeConsumingOperations.CancelJobExecution(JobID);
		JobID = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Function UpgradeOfMFPFacilitiesHasBeenCompleted()
	
	Result = True;
	
	If Not Constants.DeferredUpdateCompletedSuccessfully.Get() Then
		
		MFPObjects = New Array;
		MFPObjects.Add(Metadata.Catalogs.FinancialAccountingChartsOfAccounts);
		MFPObjects.Add(Metadata.Catalogs.FinancialReportItems);
		MFPObjects.Add(Metadata.Catalogs.FinancialReportTypes);
		MFPObjects.Add(Metadata.AccountingRegisters.International);
		MFPObjects.Add(Metadata.AccountingRegisters.InternationalWithoutCorrespondence);
		
		ThereAreMFUKObjectsForUpdating = InfobaseUpdate.HasDataToProcess(Undefined, MFPObjects);
		
		Items.CreateSet.Enabled = Not ThereAreMFUKObjectsForUpdating;
		Items.ListOfSets.ChangeRowSet = Not ThereAreMFUKObjectsForUpdating;
		Items.CopyList.ChangeRowSet = Not ThereAreMFUKObjectsForUpdating;
		
		Result = Not ThereAreMFUKObjectsForUpdating;
		
	EndIf;
	
	Return Result;
		
EndFunction

#EndRegion

#EndRegion

#EndRegion
