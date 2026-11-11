
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Items.ListMonthOfDisposal.Format = NStr("vi = 'DF=''MMMM yyyy''';
											|ru = 'ДФ=''ММММ гггг''';
											|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
											|it = 'DF=''MMMM yyyy''';
											|pl = 'DF=''MMMM yyyy''';
											|tr = 'DF=''MMMM yyyy'''");
	
	If FilterDate.StartDate = '000101010000'
		And FilterDate.EndDate = '000101010000' Then
		FilterDate.Variant = StandardPeriodVariant.ThisMonth;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Decomissioning"
		Or EventName = "Write_OtherGoodsRecordingAsReceived"
		Or EventName = "Write_DisposeFixedAssets2_4" Then
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
	
	If FilterDate.StartDate = '000101010000'
		And FilterDate.EndDate = '000101010000' Then
		FilterDate.Variant = StandardPeriodVariant.ThisMonth;
	EndIf;
	
	StartUpdatingList();

EndProcedure

&AtClient
Procedure FilterDocumentWriteOffsOnChange(Item)
	
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
	
	If Field = Items.ListFixedAsset Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.FixedAsset);
		
	ElsIf Field = Items.ListDisposalDocument Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.DocumentRetirements);
		
	ElsIf Field = Items.ListDocumentWriteOffs Then
		
		StandardProcessing = False;
		
		If ValueIsFilled(CurrentData.DocumentWriteOffs) Then
			ShowValue(, CurrentData.DocumentWriteOffs);
		Else
			SelectedRows = New Array;
			SelectedRows.Add(CurrentData.GetID());
			CreateCharge(SelectedRows);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MakeDebit(Command)
	
	CreateCharge(Items.List.SelectedRows);
	
EndProcedure

&AtClient
Procedure UpdateList(Command)
	
	StartUpdatingList();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region ListDisposalDocument
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListDisposalDocument.Name);

	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
	#Region ListOfDebitedDocuments_FilledIn
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListDocumentWriteOffs.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DocumentWriteOffs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
	#Region ListOfDebitedItems_NotFilledIn
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListDocumentWriteOffs.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DocumentWriteOffs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Lập chứng từ';
													|ru = 'Оформить';
													|en = 'Register'; fa = 'ثبات';
													|it = 'Preparare';
													|pl = 'Register';
													|tr = 'Biçimlendir'"));
	#EndRegion
	
EndProcedure

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
	FunctionParameters.Insert("BeginOfPeriod", FilterDate.StartDate);
	FunctionParameters.Insert("EndOfPeriod", FilterDate.EndDate);
	FunctionParameters.Insert("Organization", FilterOrganization);
	FunctionParameters.Insert("DocumentWriteOffs", FilterDocumentWriteOffs);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "Documents.DisposeFixedAssets2_4.WorkplaceData", FunctionParameters);
	
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

&AtClient
Procedure CreateCharge(SelectedRows)
	
	ListOfParties = New Array;
	ListOfGrounds = New Array;
	
	CurMonthOfDisposal = Undefined;
	CurrentCompany = Undefined;

	CurrentDate = CommonClient.SessionDate();
	DateOfDisposal = CurrentDate;
	
	For Each RowID In SelectedRows Do
		
		RowData = List.FindByID(RowID);
		
		If ValueIsFilled(RowData.DocumentWriteOffs) Then
			Continue;
		EndIf;
		
		If RowData.MonthOfDisposal <> CurMonthOfDisposal 
			And CurMonthOfDisposal <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn thanh lý trong một tháng';
									|ru = 'Необходимо выбрать выбытие в одном месяце';
									|en = 'Select retirement within one month'; fa = 'Select retirement within one month';
									|it = 'È necessario selezionare lo smaltimento in un mese';
									|pl = 'Należy wybrać wyrejestrowanie w jednym miesiącu';
									|tr = 'Aynı ay içindeki elden çıkarmalar seçilmelidir'"));
			Return;
		EndIf;
		
		If RowData.Organization <> CurrentCompany 
			And CurrentCompany <> Undefined Then
			ShowMessageBox(, NStr("vi = 'Cần chọn các tài sản cố định của một doanh nghiệp';
									|ru = 'Необходимо выбрать основные средства одной организации';
									|en = 'Select fixed assets of one company'; fa = 'Select fixed assets of one company';
									|it = 'È necessario selezionare le immobilizzazioni di una azienda';
									|pl = 'Należy wybrać środki trwałe jednej firmy';
									|tr = 'Aynı iş yerinin sabit kıymetlerinin seçilmesi gerekmektedir'"));
			Return;
		EndIf;
		
		ListOfGrounds.Add(RowData.DocumentRetirements);
		ListOfParties.Add(RowData.Lot);
		
		CurMonthOfDisposal = RowData.MonthOfDisposal;
		CurrentCompany = RowData.Organization;
		DateOfDisposal = RowData.DateOfDisposal;
		
	EndDo;
	
	If ListOfParties.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Cần chọn tài sản cố định cần ghi giảm';
								|ru = 'Необходимо выбрать основные средства, для которых требуется оформить списание';
								|en = 'Select fixed assets that require retirement registration'; fa = 'Select fixed assets that require retirement registration';
								|it = 'È necessario selezionare le immobilizzazioni per le quali è richiesto di compilare lo storno';
								|pl = 'Należy wybrać środki trwałe, dla których należy zarejestrować rozchód';
								|tr = 'Gider yazma işlemi yapılacak sabit kıymetlerin seçilmesi gerekmektedir'"));
		Return;
		
	EndIf;
	
	If CurMonthOfDisposal < BegOfMonth(CurrentDate)
		Or CurMonthOfDisposal > EndOfMonth(CurrentDate) Then
		DocumentDate = EndOfMonth(CurMonthOfDisposal);
	Else
		DocumentDate = Max(CurrentDate, DateOfDisposal);
	EndIf;
	
	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", DocumentDate);
	TheseGrounds.Insert("Organization", CurrentCompany);
	TheseGrounds.Insert("ListOfParties", ListOfParties);
	TheseGrounds.Insert("Basis1", ListOfGrounds);
	
	FormParameters = New Structure("Basis", TheseGrounds);
	OpenForm("Document.DisposeFixedAssets2_4.ObjectForm", FormParameters);
	
EndProcedure

#EndRegion
