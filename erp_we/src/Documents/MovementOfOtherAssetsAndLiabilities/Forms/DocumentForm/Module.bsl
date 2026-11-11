
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// Control of document creation in a subordinate RIB node with filters
	DataExchangeTMERP.ControlOfCreationOfDocumentsInDistributedInformationSecurity(Object, Cancel);
	
	FillInRegisteredRecordsOfRecipients();
	IdentifierValues = New FixedMap(Documents.MovementOfOtherAssetsAndLiabilities.IdentifierValues());
	MovementDescriptions = New FixedMap(Documents.MovementOfOtherAssetsAndLiabilities.RegisterRecordsDetails());
	LongDesc = GenerateDescription(Object, MovementDescriptions);
	Source = Object.Source;
	Recipient = Object.Recipient;
	Increase = Object.Increase;
	
	If Object.Ref.IsEmpty() Then
		UpdateDescription_(Object, Items, Object.LongDesc, MovementDescriptions);
	Else
		NamesArray = New Array(1);
		NamesArray[0] = LongDesc;
		Items.LongDesc.ChoiceList.LoadValues(NamesArray);
	EndIf;
	
	SetVisibility1();
	
	ItemsAndDimensionsSelectionParameters = Documents.MovementOfOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters(Object.Source, Object.Recipient);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	LongDesc = GenerateDescription(Object, MovementDescriptions);
	Source = Object.Source;
	Recipient = Object.Recipient;
	Increase = Object.Increase;
	
	SetVisibility1();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

	CalculateTotals_();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, NotificationSource)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.MovementOfOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters(Object.Source, Object.Recipient);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.MovementOfOtherAssetsAndLiabilities.Form.RecordsSelectionForm" Then
		ProcessingSelectionOfResidues(ValueSelected.AddressOfBalancesInStorage);
	ElsIf ChoiceSource.FormName = "Document.MovementOfOtherAssetsAndLiabilities.Form.FormOfSelectionOfPostingTypes" Then
		ProcessingMotionTypeSelection(ValueSelected);
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure LongDescStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpenForm("Document.MovementOfOtherAssetsAndLiabilities.Form.FormOfSelectionOfPostingTypes", , ThisForm);
	
EndProcedure

&AtClient
Procedure LongDescOnChange(Item)
	
	If Object.LongDesc = GenerateDescription(Object, MovementDescriptions) Then
		LongDesc = Object.LongDesc;
	EndIf;
	
EndProcedure

&AtClient
Procedure SourceOnChange(Item)
	
	If Not ItIsNecessaryToClarifyChangeInTypeOfRegisteredRecords("AnswerToSourceChangeQuestion") Then
		UpdateDescription_(Object, Items, LongDesc, MovementDescriptions);
		Source = Object.Source;
		SetVisibility1();
	EndIf;
	
EndProcedure

&AtClient
Procedure IncreaseRecipientOnChange(Item)
	
	IdStrings = StrSplit(IncreaseRecipient, "\");
	
	Object.Increase = IdentifierValues[IdStrings[0]];
	Object.Recipient = IdentifierValues[IdStrings[1]];
	
	If Not Object.Increase Then
		If Object.Recipient = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.AssetItem") 
			And Object.Source = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.AssetItem") Then
			Object.Source = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.LiabilityItem");
		ElsIf Object.Recipient = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.LiabilityItem")
			And Object.Source <> PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.ExpenseItem")
			And Object.Source <> PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.IncomeItem") Then
			Object.Source = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.ExpenseItem");
		EndIf;
	ElsIf Object.Recipient = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.LiabilityItem")
		And Object.Source = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.AssetItem") Then
		Object.Source = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.LiabilityItem");
	EndIf;
	
	If Not ItIsNecessaryToClarifyChangeInTypeOfRegisteredRecords("AnswerToRecipientChangesQuestion") Then
		UpdateDescription_(Object, Items, LongDesc, MovementDescriptions);
		Source = Object.Source;
		Recipient = Object.Recipient;
		Increase = Object.Increase;
		SetVisibility1();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure PostingDataOnChange(Item)
	
	CalculateTotals_();
	
EndProcedure

&AtClient
Procedure PostingDataOnStartEdit(Item, NewRow, Copy)
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.PostingData");
EndProcedure

&AtClient
Procedure PostingDataItemRecipientOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure PostingDataSourceItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure PostingDataExpensesDimensionSourceStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure PostingDataExpensesDimensionSourceAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure PostingDataExpensesDimensionSourceTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure PostingDataExpensesDimensionRecipientStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure PostingDataExpensesDimensionRecipientAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure PostingDataExpensesDimensionRecipientTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInReceiptItem(Command)
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.PostingDataItemRecipient, Items.PostingData.SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInTheExpenseItem(Command)
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.PostingDataSourceItem, Items.PostingData.SelectedRows);
	
EndProcedure

&AtClient
Procedure SourceRemainingQuantitySelection(Command)
	
	SelectionOfResidues_("Source");
	
EndProcedure

&AtClient
Procedure RecipientRemainingQuantitySelection(Command)
	
	SelectionOfResidues_("Recipient");
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private
	
&AtServer
Procedure FillInRegisteredRecordsOfRecipients()
	
	Increase = True;
	TypesOfArticles = Enums.TypesOfAssetAndLiabilityItems;
	
	RecipientSRegisteredRecords = Items.IncreaseRecipient.ChoiceList;
	RecipientSRegisteredRecords.Add(RegisteredRecordedID(Increase, TypesOfArticles.AssetItem), NStr("vi = 'tăng tài sản';
																									|ru = 'увеличение активов';
																									|en = 'asset increase'; fa = 'asset increase';
																									|it = 'увеличение активов';
																									|pl = 'asset increase';
																									|tr = 'varlıkların artışı'"));
	RecipientSRegisteredRecords.Add(RegisteredRecordedID(Increase, TypesOfArticles.LiabilityItem), NStr("vi = 'tăng nguồn vốn';
																										|ru = 'увеличение пассивов';
																										|en = 'liability increase'; fa = 'liability increase';
																										|it = 'incremento dei passivi';
																										|pl = 'zwiększenie zobowiązań';
																										|tr = 'yükümlülüklerin artması'"));
	RecipientSRegisteredRecords.Add(RegisteredRecordedID(Not Increase, TypesOfArticles.AssetItem), NStr("vi = 'giảm tài sản';
																										|ru = 'уменьшение активов';
																										|en = 'asset decrease'; fa = 'asset decrease';
																										|it = 'уменьшение активов';
																										|pl = 'asset decrease';
																										|tr = 'varlıkların düşüşü'"));
	RecipientSRegisteredRecords.Add(RegisteredRecordedID(Not Increase, TypesOfArticles.LiabilityItem), NStr("vi = 'giảm nguồn vốn';
																											|ru = 'уменьшение пассивов';
																											|en = 'liability decrease'; fa = 'liability decrease';
																											|it = 'уменьшение пассивов';
																											|pl = 'liability decrease';
																											|tr = 'yükümlülüklerin düşüşü'"));
	
	IncreaseRecipient = RegisteredRecordedID(Object.Increase, Object.Recipient);
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	TypeOfRegisteredRecords - Structure of KeyAndValue - LongDesc:
// 
&AtClient
Procedure ProcessingMotionTypeSelection(TypeOfRegisteredRecords)
	
	If Not TypeOf(TypeOfRegisteredRecords) = Type("Structure") Then
		Return;
	EndIf;
	
	Source = TypeOfRegisteredRecords.Source;
	Recipient = TypeOfRegisteredRecords.Recipient;
	Increase = TypeOfRegisteredRecords.Increase;
	
	If Not ItIsNecessaryToClarifyChangeInTypeOfRegisteredRecords("AnswerToQuestionOfChangingTypeOfRegisteredRecords", TypeOfRegisteredRecords) Then
		FillPropertyValues(Object, TypeOfRegisteredRecords);
		IncreaseRecipient = RegisteredRecordedID(Object.Increase, Object.Recipient);
		SetVisibility1();
	EndIf;
	
EndProcedure

&AtClient
Function ItIsNecessaryToClarifyChangeInTypeOfRegisteredRecords(Handler, HandlerParameters = Undefined)
	
	If Object.PostingData.Count()
		And (Object.Source <> Source Or Object.Recipient <> Recipient Or Object.Increase <> Increase) Then
		
		QueryText = NStr("vi = 'Phần bảng chứng từ sẽ bị xóa, tiếp tục?';
						|ru = 'Табличная часть документа будет очищена, продолжить?';
						|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
						|it = 'La parte tabulare del documento verrà cancellata, continuare?';
						|pl = 'Część tabelaryczna dokumentu zostanie wyczyszczona, kontynuować?';
						|tr = 'Belgenin tablo bölümü temizlenecek, devam edilsin mi?'");
		Notification = New CallbackDescription(Handler, ThisForm, HandlerParameters);
		
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure AnswerToQuestionOfChangingTypeOfRegisteredRecords(Result, TypeOfRegisteredRecords) Export
	
	If Result = DialogReturnCode.No Then
		Source = Object.Source;
		Recipient = Object.Recipient;
		Increase = Object.Increase;
	Else
		Object.PostingData.Clear();
		If Not TypeOfRegisteredRecords = Undefined Then
			FillPropertyValues(Object, TypeOfRegisteredRecords);
			IncreaseRecipient = RegisteredRecordedID(Object.Increase, Object.Recipient);
		EndIf;
		SetVisibility1();
	EndIf;
	
EndProcedure 

&AtClient
Procedure AnswerToSourceChangeQuestion(Result, AddlParameters) Export
	
	If Result = DialogReturnCode.No Then
		Object.Source = Source;
	Else
		UpdateDescription_(Object, Items, LongDesc, MovementDescriptions);
		Object.PostingData.Clear();
		Source = Object.Source;
		SetVisibility1();
	EndIf;
	
EndProcedure 

&AtClient
Procedure AnswerToRecipientChangesQuestion(Result, AddlParameters) Export
	
	If Result = DialogReturnCode.No Then
		Object.Source = Source;
		Object.Recipient = Recipient;
		Object.Increase = Increase;
		IncreaseRecipient = RegisteredRecordedID(Object.Increase, Object.Recipient);
	Else
		UpdateDescription_(Object, Items, LongDesc, MovementDescriptions);
		Object.PostingData.Clear();
		Source = Object.Source;
		Recipient = Object.Recipient;
		Increase = Object.Increase;
		SetVisibility1();
	EndIf;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure UpdateDescription_(Object, Items, FormerName, MovementDescriptions)
	
	// New element name
	NewName = GenerateDescription(Object, MovementDescriptions);
	
	If IsBlankString(Object.LongDesc) Or Object.LongDesc = FormerName Then
		Object.LongDesc = NewName;
	EndIf;
	
	FormerName = NewName;
	
	// List of names
	NamesArray = New Array(1);
	NamesArray[0] = NewName;
	
	Items.LongDesc.ChoiceList.LoadValues(NamesArray);
	
EndProcedure

&AtClientAtServerNoContext
Function GenerateDescription(Object, MovementDescriptions)
	
	If Not ValueIsFilled(Object.Source)
	 Or Not ValueIsFilled(Object.Recipient)
	 Or Object.Recipient = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.IncomeItem")
	 Or Object.Recipient = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.ExpenseItem") Then
		Return Undefined;
	ElsIf Not Object.Increase Then
		If Object.Recipient = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.AssetItem") 
			And Object.Source = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.AssetItem") Then
			Return Undefined;
		ElsIf Object.Recipient = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.LiabilityItem")
			And Object.Source <> PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.ExpenseItem")
			And Object.Source <> PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.IncomeItem") Then
			Return Undefined;
		EndIf;
	ElsIf Object.Recipient = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.LiabilityItem")
		And Object.Source = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.AssetItem") Then
		Return Undefined;
	EndIf;
	
	RegisteredRecordedID = RegisteredRecordedID(Object.Increase, Object.Recipient, Object.Source);
	
	Return MovementDescriptions[RegisteredRecordedID];
	
EndFunction

&AtServerNoContext
Function RegisteredRecordedID(Increase, Recipient, Source = Undefined)
	
	Return Documents.MovementOfOtherAssetsAndLiabilities.RegisteredRecordedID(Increase, Recipient, Source);
	
EndFunction

&AtServer
Function MovementTypeSideData(ArticleType, Postfix = "")
	
	// Initializing the structure
	Data = New Structure;
	Data.Insert("Name", "");
	Data.Insert("Type", Undefined);
	Data.Insert("Filter", New Array);
	Data.Insert("FilterDirections", New Array);
	
	AssetLiability = New Array;
	AssetLiability.Add(Enums.KindsOfBalanceSheetStatementItems.AssetLiability);
	If ArticleType = Enums.TypesOfAssetAndLiabilityItems.IncomeItem Then
		
		Data.Name = NStr("vi = 'thu nhập';
						|ru = 'доходов';
						|en = 'income'; fa = 'income';
						|it = 'dei ricavi';
						|pl = 'income';
						|tr = 'gelirlerin'") + Postfix;
		Data.Type = New TypeDescription("ChartOfCharacteristicTypesRef.IncomeItems");
		Data.FilterDirections.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
		
	ElsIf ArticleType = Enums.TypesOfAssetAndLiabilityItems.ExpenseItem Then
		
		Data.Name = NStr("vi = 'chi phí';
						|ru = 'расходов';
						|en = 'expenses'; fa = 'expenses';
						|it = 'dei costi';
						|pl = 'expenses';
						|tr = 'giderlerin'") + Postfix;
		Data.Type = New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems");
		Data.FilterDirections.Add(New ChoiceParameter("Filter.CostAccounting", True));
		
	ElsIf ArticleType = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem Then
		
		Data.Name = NStr("vi = 'nguồn vốn';
						|ru = 'пассивов';
						|en = 'liabilities'; fa = 'liabilities';
						|it = 'passivi';
						|pl = 'liabilities';
						|tr = 'yükümlülüklerin'") + Postfix;
		Data.Type = New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
		AssetLiability.Add(Enums.KindsOfBalanceSheetStatementItems.Liabilities);
		Data.Filter.Add(New ChoiceParameter("Filter.AssetLiability", AssetLiability));
		Data.FilterDirections.Add(New ChoiceParameter("Ref", Object.Ref));
		
	Else
		
		Data.Name = NStr("vi = 'tài sản';
						|ru = 'активов';
						|en = 'assets'; fa = 'assets';
						|it = 'attivi';
						|pl = 'assets';
						|tr = 'varlıkların'") + Postfix;
		Data.Type = New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
		AssetLiability.Add(Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName);
		Data.Filter.Add(New ChoiceParameter("Filter.AssetLiability", AssetLiability));
		Data.FilterDirections.Add(New ChoiceParameter("Ref", Object.Ref));
		
	EndIf;
	
	Return Data;
	
EndFunction

&AtServer
Procedure FormItemsManagement()
	
	Items.Currency.Visible = GetFunctionalOption("UseMultipleCurrencies");
	
	SourcePostfix = "";
	RecipientSPostfix = "";
	If Object.Source = Object.Recipient Then
		SourcePostfix  = " " + ?(Object.Increase, NStr("vi = '(Chi)';
														|ru = '(Расход)';
														|en = '(Outflow)'; fa = '(Outflow)';
														|it = '(Uscite)';
														|pl = '(Rozchód)';
														|tr = '(Gider)'"), NStr("vi = '(Thu)';
																				|ru = '(Приход)';
																				|en = '(Inflow)'; fa = '(Inflow)';
																				|it = '(Entrate)';
																				|pl = '(Wpłata)';
																				|tr = '(Giriş)'"));
		RecipientSPostfix = " " + ?(Object.Increase, NStr("vi = '(Thu)';
															|ru = '(Приход)';
															|en = '(Inflow)'; fa = '(Inflow)';
															|it = '(Entrate)';
															|pl = '(Wpłata)';
															|tr = '(Giriş)'"), NStr("vi = '(Chi)';
																					|ru = '(Расход)';
																					|en = '(Outflow)'; fa = '(Outflow)';
																					|it = '(Uscite)';
																					|pl = '(Rozchód)';
																					|tr = '(Gider)'"));
	EndIf;
	
	SourceData = MovementTypeSideData(Object.Source, SourcePostfix);
	RecipientData = MovementTypeSideData(Object.Recipient, RecipientSPostfix);
	
	// Recipient
	Items.PostingDataRecipientRemainingQuantitySelection.Title	= NStr("vi = 'Chọn';
																		|ru = 'Подбор';
																		|en = 'Pick'; fa = 'انتخاب';
																		|it = 'Selezione';
																		|pl = 'Pick';
																		|tr = 'Seçim'") + " " + RecipientData.Name;
	Items.PostingDataRecipientRemainingQuantitySelection.Visible	= Not Object.Increase;
	Items.PostingDataItemRecipient.Title			= NStr("vi = 'Dạng';
															|ru = 'Статья';
															|en = 'Item'; fa = 'قلم';
															|it = 'Voce';
															|pl = 'Item';
															|tr = 'Kalem'") +" " +  RecipientData.Name;
	Items.ReflectionDataFillInTheRecipientArticle.Title	= NStr("vi = 'Dạng';
																	|ru = 'Статью';
																	|en = 'Item'; fa = 'قلم';
																	|it = 'Voce';
																	|pl = 'Item';
																	|tr = 'Kalem'") + " " + RecipientData.Name;
	Items.PostingDataReceivingBusinessUnit.Title	= NStr("vi = 'Bộ phận';
															|ru = 'Подразделение';
															|en = 'Business unit'; fa = 'Business unit';
															|it = 'Reparto';
															|pl = 'Dział';
															|tr = 'Departman'") + " " + RecipientData.Name;
	Items.ReflectionDataDestinationRecipient.Title	= NStr("vi = 'Lĩnh vực hoạt động';
															|ru = 'Направление деятельности';
															|en = 'Line of business'; fa = 'خط کسب‌وکار';
															|it = 'Settore di attività';
															|pl = 'Rodzaj działalności';
															|tr = 'İş kolu'") + " " + RecipientData.Name;
	Items.ReflectionDataDestinationRecipient.ChoiceParameters = New FixedArray(RecipientData.FilterDirections);
	
	// Source
	Items.PostingDataSourceRemainingQuantitySelection.Title	= NStr("vi = 'Chọn';
																		|ru = 'Подбор';
																		|en = 'Pick'; fa = 'انتخاب';
																		|it = 'Selezione';
																		|pl = 'Pick';
																		|tr = 'Seçim'") + " " + SourceData.Name;
	Items.PostingDataSourceRemainingQuantitySelection.Visible	= Object.Increase;
	Items.PostingDataSourceItem.Title			= NStr("vi = 'Dạng';
														|ru = 'Статья';
														|en = 'Item'; fa = 'قلم';
														|it = 'Voce';
														|pl = 'Item';
														|tr = 'Kalem'") + " " + SourceData.Name;
	Items.ReflectionDataFillInTheArticleSource.Title	= NStr("vi = 'Dạng';
																|ru = 'Статью';
																|en = 'Item'; fa = 'قلم';
																|it = 'Voce';
																|pl = 'Item';
																|tr = 'Kalem'") + " " + SourceData.Name;
	Items.PostingDataBusinessUnitSource.Title		= NStr("vi = 'Bộ phận';
															|ru = 'Подразделение';
															|en = 'Business unit'; fa = 'Business unit';
															|it = 'Reparto';
															|pl = 'Dział';
															|tr = 'Departman'") + " " + SourceData.Name;
	Items.ReflectionDataDirectionSource.Title	= NStr("vi = 'Lĩnh vực hoạt động';
														|ru = 'Направление деятельности';
														|en = 'Line of business'; fa = 'خط کسب‌وکار';
														|it = 'Settore di attività';
														|pl = 'Rodzaj działalności';
														|tr = 'İş kolu'") + " " + SourceData.Name;
	Items.ReflectionDataDirectionSource.ChoiceParameters = New FixedArray(SourceData.FilterDirections);
	
	Items.PostingDataBusinessUnitSource.AutoMarkIncomplete = Undefined;
	If Source = Enums.TypesOfAssetAndLiabilityItems.AssetItem
		Or Source = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem Then
		Items.PostingDataBusinessUnitSource.AutoMarkIncomplete = False;
	EndIf;
	
	ArticleSelectionOptions = Documents.MovementOfOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters(Object.Source, Object.Recipient);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisForm, ArticleSelectionOptions);
	
	FillInSourcesPresentation();
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.MovementOfOtherAssetsAndLiabilities.FillInNamesOfBusinessTransactionDetails(
		Object.Source,
		Object.Recipient,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CalculateTotals_()
	
	TotalAmount_4 = Object.PostingData.Total("Sum");
	
EndProcedure

&AtClient
Procedure SelectionOfResidues_(ArticleType)
	
	AssetItem = PredefinedValue("Enum.TypesOfAssetAndLiabilityItems.AssetItem");
	
	PickingParameters = New Structure;
	PickingParameters.Insert("TableSide",	ArticleType);
	PickingParameters.Insert("Currency",			Object.Currency);
	PickingParameters.Insert("DocumentRef",	Object.Ref);
	PickingParameters.Insert("Organization",	Object.Organization);
	PickingParameters.Insert("ArticleType",		?(Object[ArticleType].IsEmpty(), AssetItem, Object[ArticleType]));
	PickingParameters.Insert("Date",			Object.Date);
	
	OpenForm("Document.MovementOfOtherAssetsAndLiabilities.Form.RecordsSelectionForm",
		PickingParameters,
		ThisForm);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfResidues(AddressOfBalancesInStorage) 
	
	BalanceTable = GetFromTempStorage(AddressOfBalancesInStorage);
	
	If Not BalanceTable = Undefined Then
		
		For Each RemainderLine_ In BalanceTable Do
			FillPropertyValues(Object.PostingData.Add(), RemainderLine_);
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LongDescOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.LongDesc");
	
EndProcedure

&AtServer
Procedure FillInSourcesPresentation()
	
	ChoiceList = Items.Source.ChoiceList;
	ChoiceList.Clear();
	
	If Recipient = Enums.TypesOfAssetAndLiabilityItems.AssetItem Then
		
		If Increase Then
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.AssetItem,  NStr("vi = 'giảm tài sản khác';
																				|ru = 'уменьшение других активов';
																				|en = 'other asset decrease'; fa = 'other asset decrease';
																				|it = 'diminuzione di altri attivi';
																				|pl = 'zmniejszenie innych aktywów';
																				|tr = 'diğer varlıkların azalması'"));
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.LiabilityItem, NStr("vi = 'tăng nguồn vốn';
																					|ru = 'увеличение пассивов';
																					|en = 'liability increase'; fa = 'liability increase';
																					|it = 'incremento dei passivi';
																					|pl = 'zwiększenie zobowiązań';
																					|tr = 'yükümlülüklerin artması'"));
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.ExpenseItem, NStr("vi = 'giảm chi phí';
																				|ru = 'уменьшение расходов';
																				|en = 'expense decrease'; fa = 'expense decrease';
																				|it = 'уменьшение расходов';
																				|pl = 'expense decrease';
																				|tr = 'giderlerin düşüşü'"));
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.IncomeItem,  NStr("vi = 'tạo thu nhập';
																				|ru = 'возникновение доходов';
																				|en = 'income incurrence'; fa = 'income incurrence';
																				|it = 'generazione ricavi';
																				|pl = 'powstanie dochodów';
																				|tr = 'gelirlerin oluşumu'"));
		Else
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.LiabilityItem, NStr("vi = 'giảm nguồn vốn';
																					|ru = 'уменьшение пассивов';
																					|en = 'liability decrease'; fa = 'liability decrease';
																					|it = 'уменьшение пассивов';
																					|pl = 'liability decrease';
																					|tr = 'yükümlülüklerin düşüşü'"));
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.ExpenseItem, NStr("vi = 'phát sinh chi phí';
																				|ru = 'возникновение расходов';
																				|en = 'expense incurrence'; fa = 'expense incurrence';
																				|it = 'generazione costi';
																				|pl = 'powstanie rozchodów';
																				|tr = 'giderlerin oluşumu'"));
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.IncomeItem,  NStr("vi = 'giảm thu nhập';
																				|ru = 'уменьшение доходов';
																				|en = 'income decrease'; fa = 'income decrease';
																				|it = 'diminuzione ricavi';
																				|pl = 'zmniejszenie dochodów';
																				|tr = 'gelirlerin azalması'"));
		EndIf;
		
	ElsIf Recipient = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem Then
		
		If Increase Then
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.LiabilityItem, NStr("vi = 'giảm nguồn vốn khác';
																					|ru = 'уменьшение других пассивов';
																					|en = 'other liability decrease'; fa = 'other liability decrease';
																					|it = 'diminuzione di altri passivi';
																					|pl = 'zmniejszenie innych zobowiązań';
																					|tr = 'diğer yükümlülüklerin azalması'"));
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.ExpenseItem, NStr("vi = 'phát sinh chi phí';
																				|ru = 'возникновение расходов';
																				|en = 'expense incurrence'; fa = 'expense incurrence';
																				|it = 'generazione costi';
																				|pl = 'powstanie rozchodów';
																				|tr = 'giderlerin oluşumu'"));
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.IncomeItem,  NStr("vi = 'giảm thu nhập';
																				|ru = 'уменьшение доходов';
																				|en = 'income decrease'; fa = 'income decrease';
																				|it = 'diminuzione ricavi';
																				|pl = 'zmniejszenie dochodów';
																				|tr = 'gelirlerin azalması'"));
		Else
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.ExpenseItem, NStr("vi = 'giảm chi phí';
																				|ru = 'уменьшение расходов';
																				|en = 'expense decrease'; fa = 'expense decrease';
																				|it = 'уменьшение расходов';
																				|pl = 'expense decrease';
																				|tr = 'giderlerin düşüşü'"));
			ChoiceList.Add(Enums.TypesOfAssetAndLiabilityItems.IncomeItem,  NStr("vi = 'tạo thu nhập';
																				|ru = 'возникновение доходов';
																				|en = 'income incurrence'; fa = 'income incurrence';
																				|it = 'generazione ricavi';
																				|pl = 'powstanie dochodów';
																				|tr = 'gelirlerin oluşumu'"));
		EndIf;
		
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties 

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);

EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
