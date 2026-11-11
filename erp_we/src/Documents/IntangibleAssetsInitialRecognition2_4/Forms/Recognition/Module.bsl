
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If FilterDate.Date = '000101010000' Then
		FilterDate.Variant = StandardBeginningDateVariant.BeginningOfThisDay;
	EndIf;

	If Not AccessRight("InteractiveInsert", Metadata.Documents.IntangibleAssetsInitialRecognition2_4) Then
		Items.ListIssueAcceptanceForAccounting.Visible = False;
	EndIf;
	If Not AccessRight("InteractiveInsert", Metadata.Documents.IntangibleAssetImprovement) Then
		Items.ListIssueIAImprovement.Visible = False;
		Items.ListIssueInclusionOfExpensesInCostOfIA.Visible = False;
	EndIf;
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently() Then
		Items.ListGroupState.ShowInHeader = False;
		Items.ListBUState.Visible = False;
		Items.ListStateOfTheUU.Title = NStr("vi = 'Trạng thái';
											|ru = 'Состояние';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Состояние';
											|pl = 'State';
											|tr = 'Durum'");
	EndIf;
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_IntangibleAssetsInitialRecognition2_4"
		Or EventName = "Write_IntangibleAssetImprovement" Then
		UpdateDataWhenFormBecomesActive();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure FilterDateOnChange(Item)
	
	If FilterDate.Date = '000101010000' Then
		FilterDate.Variant = StandardBeginningDateVariant.BeginningOfThisDay;
	EndIf;

	StartUpdatingList();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ListRef Then
		StandardProcessing = False;
		ShowValue(, CurrentData.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueAcceptanceForAccounting(Command)
	
	FormParameters = ParametersOfRegistrationForm();
	
	If FormParameters <> Undefined Then
		OpenForm("Document.IntangibleAssetsInitialRecognition2_4.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueIAImprovement(Command)
	
	FormParameters = ParametersOfIAImprovementForm();
	
	If FormParameters <> Undefined Then
		FormParameters.Basis.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.IntangibleAssetImprovement"));
		OpenForm("Document.IntangibleAssetImprovement.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueInclusionOfExpensesInCostOfIA(Command)
	
	FormParameters = ParametersOfIAImprovementForm();
	
	If FormParameters <> Undefined Then
		FormParameters.Basis.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost"));
		OpenForm("Document.IntangibleAssetImprovement.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateList(Command)
	
	StartUpdatingList();

EndProcedure

&AtClient
Procedure CapitalizationCostStructureReport(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;

	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("VariantKey", "CostStructure_");
	FormParameters.Insert("CommandParameter", CurrentData.Ref);
	FormParameters.Insert("CommandDetails", New Structure);
	OpenForm("Report.CapitalizationExpenseStructure.Form", FormParameters,, True);

EndProcedure

#EndRegion

#Region Private

&AtClient
Function ParametersOfRegistrationForm()
	
	ListOfIA = New Array;
	
	CurrentCompany = Undefined;

	For Each RowID In Items.List.SelectedRows Do
		
		RowData = List.FindByID(RowID);
		
		If RowData.Organization <> CurrentCompany 
			And CurrentCompany <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn TSCĐ vô hình của một doanh nghiệp';
									|ru = 'Необходимо выбрать НМА одной организации';
									|en = 'Select intangible assets of one company'; fa = 'Select intangible assets of one company';
									|it = 'Необходимо выбрать НМА одной организации';
									|pl = 'Select intangible assets of one company';
									|tr = 'Aynı iş yerinin maddi olmayan varlıklarının seçilmesi gerekmektedir'"));
			Return Undefined;
		EndIf;
		
		If RowData.BUState = PredefinedValue("Enum.IntangibleAssetsStates.PostedInFinancialAccounting")
			And (RowData.StateTa = PredefinedValue("Enum.IntangibleAssetsStates.PostedInFinancialAccounting")
				Or Not ComplianceCAAccountingIsKept)
			And RowData.StateOfTheUU = PredefinedValue("Enum.IntangibleAssetsStates.PostedInFinancialAccounting") Then
			ShowMessageBox(, NStr("vi = 'Không thể tiếp nhận vào kế toán TSCĐ vô hình mà đã tiếp nhận vào kế toán';
									|ru = 'Невозможно принятие к учету НМА, уже принятого к учету';
									|en = 'Cannot recognize intangible assets that are already recognized'; fa = 'Cannot recognize intangible assets that are already recognized';
									|it = 'Невозможно принятие к учету НМА, уже принятого к учету';
									|pl = 'Cannot recognize intangible assets that are already recognized';
									|tr = 'Daha önce hesaba alınmış maddi olmayan varlıklar için maddi olmayan varlıklar - ilk tahakkuk işlemi mümkün değildir'"));
			Return Undefined;
		EndIf;
		
		ListOfIA.Add(RowData.Ref);
		
		CurrentCompany = RowData.Organization;
		
	EndDo;
	
	If ListOfIA.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Không thể chọn TSCĐ vô hình';
								|ru = 'Необходимо выбрать НМА';
								|en = 'Select intangible assets'; fa = 'Select intangible assets';
								|it = 'Необходимо выбрать НМА';
								|pl = 'Select intangible assets';
								|tr = 'Maddi olmayan varlıkı seçmek gereklidir'"));
		Return Undefined;
		
	ElsIf ListOfIA.Count() > 1 Then
			
		ShowMessageBox(, NStr("vi = 'Không hỗ trợ tiếp nhận vào kế toán đồng thời nhiều TSCĐ vô hình.
									  |Cần chọn một TSCĐ vô hình.';
									  |ru = 'Не поддерживается принятие к учету одновременно нескольких НМА.
									  |Необходимо выбрать один НМА.';
									  |en = 'Recognition of multiple intangible assets at the same time is not supported.
									  |Select one intangible asset.'; fa = 'Recognition of multiple intangible assets at the same time is not supported.
									  |Select one intangible asset.';
									  |it = 'Не поддерживается принятие к учету одновременно нескольких НМА.
									  |Необходимо выбрать один НМА.';
									  |pl = 'Recognition of multiple intangible assets at the same time is not supported.
									  |Select one intangible asset.';
									  |tr = 'Aynı anda birden fazla maddi olmayan varlıkın tanınması desteklenmez. 
									  |Bir maddi olmayan varlık seçmeniz gerekir.'"));
		Return Undefined;
		
	EndIf;
	
	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", CurrentCompany);
	
	If ListOfIA.Count() = 1 Then
		TheseGrounds.Insert("IntangibleAsset", ListOfIA[0]);
	Else
		TheseGrounds.Insert("IntangibleAsset", ListOfIA);
	EndIf;
	
	FormParameters = New Structure("Basis", TheseGrounds);
	
	Return FormParameters;
	
EndFunction

&AtClient
Function ParametersOfIAImprovementForm()
	
	ListOfIA = New Array;
	
	CurrentCompany = Undefined;

	For Each RowID In Items.List.SelectedRows Do
		
		RowData = List.FindByID(RowID);
		
		If RowData.Organization <> CurrentCompany 
			And CurrentCompany <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn TSCĐ vô hình của một doanh nghiệp';
									|ru = 'Необходимо выбрать НМА одной организации';
									|en = 'Select intangible assets of one company'; fa = 'Select intangible assets of one company';
									|it = 'Необходимо выбрать НМА одной организации';
									|pl = 'Select intangible assets of one company';
									|tr = 'Aynı iş yerinin maddi olmayan varlıklarının seçilmesi gerekmektedir'"));
			Return Undefined;
		EndIf;
		
		If RowData.BUState <> PredefinedValue("Enum.IntangibleAssetsStates.PostedInFinancialAccounting")
			And (RowData.StateTa <> PredefinedValue("Enum.IntangibleAssetsStates.PostedInFinancialAccounting")
				Or Not ComplianceCAAccountingIsKept)
			And RowData.StateOfTheUU <> PredefinedValue("Enum.IntangibleAssetsStates.PostedInFinancialAccounting") Then
			ShowMessageBox(, NStr("vi = 'Không thể lập chứng từ cho TSCĐVH mà chưa tiếp nhận vào kế toán';
									|ru = 'Невозможно оформление документа для НМА, не принятого к учету';
									|en = 'Cannot register the document for an unrecognized intangible asset'; fa = 'Cannot register the document for an unrecognized intangible asset';
									|it = 'Cannot register the document for an unrecognized intangible asset';
									|pl = 'Cannot register the document for an unrecognized intangible asset';
									|tr = 'Muhasebeleştirilmemiş maddi olmayan varlık için belge oluşturulamaz'"));
			Return Undefined;
		EndIf;
		
		ListOfIA.Add(RowData.Ref);
		
		CurrentCompany = RowData.Organization;
		
	EndDo;
	
	If ListOfIA.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Không thể chọn TSCĐ vô hình';
								|ru = 'Необходимо выбрать НМА';
								|en = 'Select intangible assets'; fa = 'Select intangible assets';
								|it = 'Необходимо выбрать НМА';
								|pl = 'Select intangible assets';
								|tr = 'Maddi olmayan varlıkı seçmek gereklidir'"));
		Return Undefined;
		
	EndIf;
	
	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", CurrentCompany);
	
	If ListOfIA.Count() = 1 Then
		TheseGrounds.Insert("IntangibleAsset", ListOfIA[0]);
	Else
		TheseGrounds.Insert("IntangibleAsset", ListOfIA);
	EndIf;

	FormParameters = New Structure("Basis", TheseGrounds);
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.8, True);

EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable() Then
		StartUpdatingList();
	Else
		UpdateDataWhenFormBecomesActive();
	EndIf;

EndProcedure

&AtClient
Procedure StartUpdatingList()

	TimeConsumingOperation = StartUpdatingListOnServer();
	CallbackOnCompletion = New CallbackDescription("UpdateListCompletion", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtServer
Function StartUpdatingListOnServer()

	FunctionParameters = New Structure;
	FunctionParameters.Insert("Date", FilterDate.Date);
	FunctionParameters.Insert("Organization", FilterOrganization);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "Documents.IntangibleAssetsInitialRecognition2_4.WorkplaceData", FunctionParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure UpdateListCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;

	UpdateListOfFilesOnServer(Result.ResultAddress);
	
EndProcedure 

&AtServer
Procedure UpdateListOfFilesOnServer(Val ResultAddress)
	
	List.Clear();
	
	Result = GetFromTempStorage(ResultAddress);
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CommonClientServer.SupplementTable(Result, List);
	
EndProcedure

#EndRegion
