
#Region Public

#Region InteractiveActions

// This procedure allows you to set a period using the standard period selection dialog
//
// Parameters:
//  Object                - Arbitrary - The object which establishes the values of the period
//  PeriodParameters_      - Structure - structure properties "Datacache", "Datacentre" and in the values field names
//                              object for the property "Version" - value variant of the standard period.
//  NotificationAfterSelection - CallbackDescription - Description of the notification that is executed after the period is set. 
//                              Post-processing can be set at the call location after the period is selected.
// 
Procedure EditPeriod(Object, PeriodParameters_ = Undefined, NotificationAfterSelection = Undefined) Export
	
	If PeriodParameters_ = Undefined Then
		PeriodParameters_ = New Structure("StartDate, EndDate", "StartDate", "EndDate");
	EndIf;
	
	Dialog = New StandardPeriodEditDialog();
	If PeriodParameters_.Property("StartDate") Then
		Dialog.Period.StartDate = Object[PeriodParameters_.StartDate];
	EndIf; 
	If PeriodParameters_.Property("EndDate") Then
		Dialog.Period.EndDate = Object[PeriodParameters_.EndDate];
	EndIf; 
	If PeriodParameters_.Property("Variant") Then
		Dialog.Period.Variant = PeriodParameters_.Variant;
	EndIf; 
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",           Object);
	AdditionalParameters.Insert("PeriodParameters_", PeriodParameters_);
	If NotificationAfterSelection <> Undefined Then
		AdditionalParameters.Insert("NotificationAfterSelection", NotificationAfterSelection);
	EndIf; 
	
	Notification = New CallbackDescription(
		"EditPeriodCompletion", 
		ThisObject, 
		AdditionalParameters);
	
	Dialog.Show(Notification);

EndProcedure

// Allows you to select a period from the drop-down list
//
// Parameters:
//  Form				- Form - form for selecting a period
//  Item				- FormField - the item to open the drop-down list next to
//	PeriodType			- EnumRef.AvailableReportPeriods - type of selected period
//	BeginOfPeriod 		- Date - Beginning of the period
//	ChoiceHandler	- CallbackDescription - a handler located in the form that will be called after the selection.
//
Procedure SelectPeriodFromList(Form, Item, PeriodType, BeginOfPeriod, ChoiceHandler) Export
	
	If BeginOfPeriod = '00010101' Then
		BeginOfPeriod = TMCommonUseClientServer.BeginningOfReportPeriod(PeriodType, GeneralPurposeTMServerCall.SessionDate());
	EndIf;
	
	SelectReportPeriod(Form, Item, PeriodType, BeginOfPeriod, ChoiceHandler);
	
EndProcedure

// Handler for the "Set delete mark" command"
//
//	Parameters:
//		List - FormTable - 
//		ListType - String - type of list documents.
//		CallbackOnCompletion - CallbackDescription - an alert that should be called after an attempt to mark for deletion is completed.
//		ListUpdateOptions - Undefined, Structure - update options:
//		* Form - ClientApplicationForm - The Form in which the list of documents is located
//		* ListName - String - the name of the dynamic list Attribute on the Form
//		* UpdateList - Boolean - indicates whether the list needs to be updated
//
Procedure SetDeletionMark(List, ListType, CallbackOnCompletion = Undefined, ListUpdateOptions = Undefined) Export 
	
	SelectedRows = CheckGetLinksHighlightedInList(List);
	
	If SelectedRows.Count() = 0 Then
		
		Return;
		
	ElsIf SelectedRows.Count() = 1 Then
		
		If TypeOf(SelectedRows[0]) = Type("FormDataStructure") Then
			RowData = SelectedRows[0];
		Else
			RowData = List.RowData(SelectedRows[0]);
		EndIf;
		
		Document = RowData.Ref;
		ThereAreLinesMarkedForDeletion = RowData.DeletionMark;
		
		ReferencesArrray = New Array();
		ReferencesArrray.Add(Document);
		
		QueryText = ?(RowData.DeletionMark,
			NStr("vi = 'Bỏ đánh dấu xóa ""%Document%""?';
				|ru = 'Снять с ""%Document%"" пометку на удаление?';
				|en = 'Clear deletion mark for ""%Document%""?'; fa = 'Clear deletion mark for ""%Document%""?';
				|it = 'Rimuovere il contrassegno per cancellazione da ""%Document%"" ?';
				|pl = 'Usunąć z ""%Document%"" zaznaczenie do usunięcia?';
				|tr = '""%Document%"" için silme işaretini kaldır?'"),
			NStr("vi = 'Đánh dấu ""%Document%"" để xóa?';
				|ru = 'Пометить ""%Document%"" на удаление?';
				|en = 'Mark ""%Document%"" for deletion?'; fa = 'Mark ""%Document%"" for deletion?';
				|it = 'Contrassegnare ""%Document%""  per la cancellazione?';
				|pl = 'Zaznaczyć ""%Document%"" do usunięcia?';
				|tr = '""%Document%"" silinmek üzere işaretle?'"));
		QueryText = StrReplace(QueryText, "%Document%", Document);
		
	Else
		
		Result = GeneralPurposeTMServerCall.ReferencesToObjectsMarkedForDeletion(SelectedRows, "Ref");
		
		ReferencesArrray = Result.ReferencesArrray;
		ThereAreLinesMarkedForDeletion = Result.ThereAreLinesMarkedForDeletion;
		
		QueryText = ?(Result.ThereAreLinesMarkedForDeletion,
			NStr("vi = 'Bỏ dấu xóa các đối tượng đã chọn?';
				|ru = 'Снять с выделенных элементов пометку на удаление?';
				|en = 'Unmark selected items for deletion?'; fa = 'Unmark selected items for deletion?';
				|it = 'Rimuovere il contrassegno per la cancellazione dagli elementi selezionati?';
				|pl = 'Usunąć z wybranych elementów zaznaczenie do usunięcia?';
				|tr = 'Seçili öğelerin silme işareti kaldırılsın mı?'"),
			NStr("vi = 'Đánh dấu xóa phần tử đã chọn?';
				|ru = 'Пометить выделенные элементы на удаление?';
				|en = 'Mark the selected items for deletion?'; fa = 'Mark the selected items for deletion?';
				|it = 'Contrassegnare gli elementi selezionati per la cancellazione?';
				|pl = 'Zaznaczyć wybrane elementy do usunięcia?';
				|tr = 'Seçilen öğeleri silinmek üzere işaretle?'"));
		
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("List", 						List);
	AdditionalParameters.Insert("SelectedRows", 			ReferencesArrray);
	AdditionalParameters.Insert("ListType", 					ListType);
	AdditionalParameters.Insert("SetMarkForDeletion", 	Not ThereAreLinesMarkedForDeletion);
	AdditionalParameters.Insert("CallbackOnCompletion", 		CallbackOnCompletion);
	AdditionalParameters.Insert("ListUpdateOptions",	ListUpdateOptions);
	
	Notification = New CallbackDescription("SetDeletionMarkCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Handler of the "Hold" commands.
//
// Parameters:
//	List - FormTable -form table.
//	ListType - String - type of list documents.
//	ListUpdateOptions - Undefined, Structure - update options:
//		* Form - ClientApplicationForm - the form in which the list of documents is located.
//		* ListName - String - the name of the dynamic list Attribute on the form.
//		* UpdateList - Boolean - indicates whether the list needs to be updated.
//
Procedure PostDocuments(List, ListType, ListUpdateOptions = Undefined) Export
	
	ClearMessages();
	
	SelectedRows = CheckGetLinksHighlightedInList(List);
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ReferencesArrray = GeneralPurposeTMServerCall.DynamicListDocumentLinks(SelectedRows);
	UnpostedDocumentsData = CommonServerCall.PostDocuments(ReferencesArrray);
	
	UnpostedDocuments =
		GeneralPurposeTMServerCall.WriteToLogToInformUserAboutResultsOfCancellationOfEvent(
			UnpostedDocumentsData);
	PostedDocuments = CommonClientServer.ArraysDifference(ReferencesArrray, UnpostedDocuments);
	
	If UnpostedDocuments.Count() > 0 Then
		DialogButtons = New ValueList;
		DialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Đồng ý';
														|ru = 'ОК';
														|en = 'OK'; fa = 'تأیید';
														|it = 'OK';
														|pl = 'OK';
														|tr = 'Tamam'"));
		
		DialogText = NStr("vi = 'Không thể kết chuyển một hoặc nhiều chứng từ.';
							|ru = 'Не удалось провести один или несколько документов.';
							|en = 'Cannot post one or several documents.'; fa = 'Cannot post one or several documents.';
							|it = 'Non è possibile registrare uno o più documenti.';
							|pl = 'Nie udało się zaksięgować jeden lub kilka dokumentów.';
							|tr = 'Bir veya birkaç belge onaylanmaz.'");
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("List", List);
		AdditionalParameters.Insert("PostedDocuments", PostedDocuments);
		AdditionalParameters.Insert("ListType", ListType);
		AdditionalParameters.Insert("ListUpdateOptions", ListUpdateOptions);
		
		CallbackDescription = New CallbackDescription("CheckDocumentsPostingCompletion", ThisObject,
			AdditionalParameters);
		
		ShowQueryBox(CallbackDescription, DialogText, DialogButtons);
	Else
		NotificationOfHoldingCancellationOfDocument(List, ReferencesArrray, ListType, ListUpdateOptions);
	EndIf;
	
EndProcedure

// Handler for the "Cancel event" command.
//
// Parameters:
//	List - FormTable - form table.
//	ListType - String - type of list documents.
//	ListUpdateOptions - Undefined, Structure - update options:
//		* Form - ClientApplicationForm - the form in which the list of documents is located.
//		* ListName - String - the name of the dynamic list Attribute on the form.
//		* UpdateList - Boolean - indicates whether the list needs to be updated.
//
Procedure UndoPosting(List, ListType, ListUpdateOptions = Undefined) Export
	
	ClearMessages();
	
	SelectedRows = CheckGetLinksHighlightedInList(List);
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ReferencesArrray = GeneralPurposeTMServerCall.DynamicListDocumentLinks(SelectedRows);
	DataOnUnverifiedDocuments = GeneralPurposeTMServerCall.CancellationOfDocuments(ReferencesArrray);
	
	UnverifiedDocuments =
		GeneralPurposeTMServerCall.WriteToLogToInformUserAboutResultsOfCancellationOfEvent(
			DataOnUnverifiedDocuments, False);
	DistributedDocuments = CommonClientServer.ArraysDifference(ReferencesArrray, UnverifiedDocuments);
	
	If UnverifiedDocuments.Count() > 0 Then
		DialogButtons = New ValueList;
		DialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Đồng ý';
														|ru = 'ОК';
														|en = 'OK'; fa = 'تأیید';
														|it = 'OK';
														|pl = 'OK';
														|tr = 'Tamam'"));
		
		DialogText = NStr("vi = 'Không thể thực hiện hủy bỏ kết chuyển một hoặc một số chứng từ.';
							|ru = 'Не удалось выполнить отмену проведения одного или нескольких документов.';
							|en = 'Cannot cancel posting of one or more documents.'; fa = 'Cannot cancel posting of one or more documents.';
							|it = 'Cannot cancel posting of one or more documents.';
							|pl = 'Cannot cancel posting of one or more documents.';
							|tr = 'Bir veya birden fazla belgenin kaydı iptal edilemedi.'");
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("List", List);
		AdditionalParameters.Insert("PostedDocuments", DistributedDocuments);
		AdditionalParameters.Insert("ListType", ListType);
		AdditionalParameters.Insert("ListUpdateOptions", ListUpdateOptions);
		
		CallbackDescription = New CallbackDescription("CheckDocumentsPostingCompletion",
														ThisObject,
														AdditionalParameters);
		
		ShowQueryBox(CallbackDescription, DialogText, DialogButtons);
	Else
		NotificationOfHoldingCancellationOfDocument(List, ReferencesArrray, ListType, ListUpdateOptions);
	EndIf;
	
EndProcedure

// Invoked when you select the current date or the date of the event.
// Changes the value of the current date or event date, depending on the selected value.
//
// Parameters:
//	ValueSelected - String - the selected selection value.
//	StandardProcessing - Boolean - flag for standard event processing.
//	Form - ClientApplicationForm - form of list of documents.
//	List - DynamicList - list of documents.
//	NameOfPropsRelevance - String - name of the relevant selection line item.
//	PropsNameEventDate - String - name of the details of the date on which the document will be expired.
//
Procedure WhenSelectingRelevanceSelection(ValueSelected, StandardProcessing, Form, List, NameOfPropsRelevance, ElementNameRelevance, PropsNameEventDate) Export
	
	If ValueSelected = "ExpiresOnDate" Then
		
		StandardProcessing = False;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("List", List);
		AdditionalParameters.Insert("NameOfPropsRelevance", NameOfPropsRelevance);
		AdditionalParameters.Insert("ElementNameRelevance", ElementNameRelevance);
		AdditionalParameters.Insert("PropsNameEventDate", PropsNameEventDate);
		
		NoteText = NStr("vi = 'Chọn một ngày để hiển thị các chứng từ đã hết hạn:';
						|ru = 'Выберите дату для вывода просроченных документов:';
						|en = 'Select a date to display overdue documents:'; fa = 'Select a date to display overdue documents:';
						|it = 'Selezionare data per visualizzare i documetni scaduti:';
						|pl = 'Wybierz datę dla wyświetlenia zaległych dokumentów:';
						|tr = 'Vadesi geçmiş belgelerin çıktısının alınacağı tarihi seç:'") + " ";
		FormParameters = New Structure("NoteText, InitialValue", NoteText);
		Notification = New CallbackDescription("WhenSelectingRelevanceSelectionCompletion", ThisObject, AdditionalParameters);
		
		OpenForm("CommonForm.SelectDate",
			FormParameters, , , , ,
			Notification,
			FormWindowOpeningMode.LockWholeInterface);
		
		Return;
		
	Else
		EventDate = Date(1,1,1);
	EndIf;
	
EndProcedure

// Invokes a dialog for entering a date. If you enter an empty date, it prompts you to enter the date again.
//
// Parameters:
//	Date - Date - initial value of the dialog date. The result of the dialog will be placed on this date.
//	ToolTip - String - title text of the date input dialog.
//	DatePart - DateFractions - the use of a value of type 'date'.
//	ChoiceNotification1 - CallbackDescription - description of the notification after selecting the date.
//
Procedure EnterDateWithControlOfEmptyValue(Date, ToolTip, DatePart, ChoiceNotification1) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Date", Date);
	AdditionalParameters.Insert("ToolTip", ToolTip);
	AdditionalParameters.Insert("DatePart", DatePart);
	AdditionalParameters.Insert("ChoiceNotification1", ChoiceNotification1);
	
	Notification = New CallbackDescription("EnterDateWithControlOfEmptyValueAfterSelection", ThisObject,
		AdditionalParameters);
	
	ShowInputDate(Notification, Date, ToolTip, DatePart);
	
EndProcedure

// Opens the date entry form.
// The date must not be empty and within the specified period.
//
// Parameters:
//	Date - Date - the initial value of the dialog date.
//	ToolTip - String - the title of the date entry dialog.
//	DatePart - DateFractions - the use of a value of type 'date'.
//	ChoiceNotification1 - CallbackDescription - description of the notification after selecting the date.
//	BeginOfPeriod - Date - the beginning of the period in which the date should be.
//	EndOfPeriod - Date - the end of the period in which the date should be.
//
Procedure ShowDateSelection(Date, ToolTip, DatePart, ChoiceNotification1, BeginOfPeriod = '000101010000', EndOfPeriod = '000101010000') Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Date", Date);
	FormParameters.Insert("ToolTip", ToolTip);
	FormParameters.Insert("DatePart", DatePart);
	FormParameters.Insert("BeginOfPeriod", BeginOfPeriod);
	FormParameters.Insert("EndOfPeriod", EndOfPeriod);
	
	OpenForm("CommonForm.DateEntry", FormParameters,,,,, ChoiceNotification1);
	
EndProcedure

// Handler for the "Edit" command"
//
// Parameters:
//  List - FormTable - form table:
//  	* CurrentData - FormDataStructure - With Fields:
//  		** Ref - DocumentRef - 
Procedure ChangeElement(List) Export
	
	CurrentData = List.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.Ref) Then
		ShowValue(Undefined, CurrentData.Ref);
	EndIf;
	
EndProcedure

// Handler for the Copy command"
//
// Parameters:
//  List - FormTable - form table:
//  	* CurrentData - FormDataStructure - With Fields:
//  		** Ref - DocumentRef - 
Procedure CopyItem(List) Export
	
	CurrentData = List.CurrentData;
	If CurrentData <> Undefined Then
		Item = CurrentData.Ref;
				
		FormParameters = New Structure;
		FormParameters.Insert("CopyingValue", Item);
		
		ObjectFormName = GeneralPurposeTMServerCall.FullNameOfObjectForm(Item);
				
		OpenForm(ObjectFormName, FormParameters);
		
	EndIf;
	
EndProcedure

// Initiates the opening of the form for selecting the utility operation and document type for further creation of a new one.
//
// Parameters:
//  AddressOfAvailableBusinessTransactionsAndDocuments	 - String - address in temporary storage with a table of available households. operations and documents
//  FormKey										 - String - form key
//  PurposeUseKey						 - String - settings key
//  FilterStructure1									 - Structure - structure with selections to fill in the document.
//
Procedure CreateDocumentViaSelectionForm(AddressOfAvailableBusinessTransactionsAndDocuments, FormKey, PurposeUseKey, FilterStructure1) Export
	
	FormParameters = New Structure();
	FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", AddressOfAvailableBusinessTransactionsAndDocuments);
	FormParameters.Insert("CreateMode", True);
	FormParameters.Insert("FormKey", FormKey);
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	AdditionalNotificationParameters = New Structure("FillingValues",FilterStructure1);
	OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
		FormParameters,,,,,
		New CallbackDescription("CreateAfterSelectingDocument",
			ThisObject, AdditionalNotificationParameters));
	
EndProcedure

// Notification handler called after the create Document (...)
Procedure CreateAfterSelectingDocument(ValueSelected, AdditionalParameters) Export 
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	FillingValues = AdditionalParameters.FillingValues;
	
	DocumentName = GeneralPurposeTMServerCall.ObjectAttributeValue(ValueSelected.MetadataObjectID, "Name");
	
	CreateDocument(ValueSelected.BusinessOperation, FillingValues, DocumentName);
		
EndProcedure

// Creates a document using a specially named command
//
// Parameters:
//  CommandName	 - String - the name of the command that was previously programmatically generated, such as Admittancommission_Purchase of goods and services,
//  FilterStructure1	- Structure - structure with selections to fill in the document.
//
Procedure CreateDocumentUsingCommand(Val CommandName, FilterStructure1) Export
			
	NamesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(CommandName,"___");
	
	EnumerationValueName 	= NamesArray[1];
	DocumentName 				= NamesArray[2];
	
	BusinessOperation = PredefinedValue("Enum.BusinessTransactions." + EnumerationValueName);

	CreateDocument(BusinessOperation, FilterStructure1, DocumentName);
	
EndProcedure

// Sets the status for selected documents
//
// Parameters:
//  CommandName					 - String	 - Name of the form command
//  CorrespondenceOfCommandsToStatuses	 - Map	 - match that is stored in the details of the current form
//  List						 - FormField	 - the list of the Form where the Statuses will be changed
//  ListUpdateOptions - Undefined, Structure - update options:
//		* Form - ClientApplicationForm - The Form in which the list of documents is located
//		* ListName - String - the name of the dynamic list Attribute on the Form
//		* UpdateList - Boolean - indicates whether the list needs to be updated
//
Procedure SetStatus(CommandName, CorrespondenceOfCommandsToStatuses, List, ListUpdateOptions = Undefined)Export 
	
	Filter = New Structure();
	Filter.Insert("CommandName", CommandName);
	
	StatusWasFound = CorrespondenceOfCommandsToStatuses.FindRows(Filter);
	
	If StatusWasFound.Count() > 0 Then
		
		StatusBar_ = StatusWasFound[0];
				
		SelectedRows = SelectDocumentsByMetadataNameFromSelectedRowsInList(StatusBar_.DocumentString, List);
		
		If SelectedRows.Count() = 0 Then
			ShowMessageBox(, NStr("vi = 'Không có chứng từ nào mà bạn có thể đặt trạng thái đã chọn';
									|ru = 'Не выделено ни одного документа, для которого можно установить выбранный статус';
									|en = 'No document for which the selected status can be set is selected'; fa = 'No document for which the selected status can be set is selected';
									|it = 'Non è stato selezionato neppure un documento per il quale è possibile impostare lo stato selezionato';
									|pl = 'Nie zaznaczono żadnego dokumentu, dla którego można ustanowić wybrany status';
									|tr = 'Seçilen durumun ayarlanabileceği hiçbir belge seçilmedi'"));
			Return;
		EndIf;
		
		HighlightedLinesContainShipment = False;
		TheHighlightedLinesContainMoreThanJustTheShipment = False;
		If StatusBar_.Status = PredefinedValue("Enum.StatusesOfCustomerInvoices.Shipped") Then
			ListStructure = SalesServerCall.CreateStructureOfDocumentList(SelectedRows);
			HighlightedLinesContainShipment = ListStructure.HighlightedLinesContainShipment;
			TheHighlightedLinesContainMoreThanJustTheShipment = ListStructure.TheHighlightedLinesContainMoreThanJustTheShipment;
		EndIf;
		
		If HighlightedLinesContainShipment Then
			FormParameters = New Structure();
			FormParameters.Insert("DateOfTransferOfTitleToGoods", CommonClient.SessionDate());
			FormParameters.Insert("TheHighlightedLinesContainMoreThanJustTheShipment", TheHighlightedLinesContainMoreThanJustTheShipment);
			
			ParametersStructure = New Structure;
			ParametersStructure.Insert("SelectedRows", SelectedRows);
			ParametersStructure.Insert("ProcessedList", 	List);
			ParametersStructure.Insert("StatusPresentation", 	StatusBar_.StatusPresentation);
			ParametersStructure.Insert("StatusValueName", 		StatusBar_.StatusValueName);
			ParametersStructure.Insert("ListUpdateOptions", ListUpdateOptions);
			
			OpenForm("Document.CustomerInvoice.Form.QuestionOnStatusChange", 
				FormParameters,,,,,
				New CallbackDescription("SetStatusImplementedCompletion", 
					ThisObject,
					ParametersStructure),
				FormWindowOpeningMode.LockWholeInterface);
		Else
			QueryText = NStr("vi = 'Các phần được chọn trong danh sách chứng từ sẽ được đặt trạng thái ""%StatusPresentation%"". Tiếp tục?';
							|ru = 'У выделенных в списке документов будет установлен статус ""%StatusPresentation%"". Продолжить?';
							|en = 'Status of the documents selected in the list will be set to ""%StatusPresentation%"". Continue?'; fa = 'Status of the documents selected in the list will be set to ""%StatusPresentation%"". Continue?';
							|it = 'Per i documenti selezionati nell''elenco verrà impostato lo stato ""%StatusPresentation%"". Continuare?';
							|pl = 'Dla zaznaczonych w liście dokumentów będzie ustanowiony status ""%StatusPresentation%"". Kontynuować?';
							|tr = 'Listede seçilen belgelerin durumu ""%StatusPresentation%"" olarak ayarlanacaktır. Devam edilsin mi?'");
			QueryText = StrReplace(QueryText, "%StatusPresentation%", StatusBar_.StatusPresentation);
			
			Mode = New ValueList;
			Mode.Add(DialogReturnCode.Yes,NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Impostare';
												|pl = 'Set';
												|tr = 'Ayarla'"));
			Mode.Add(DialogReturnCode.No,NStr("vi = 'Không đặt';
												|ru = 'Не устанавливать';
												|en = 'Do not set'; fa = 'Do not set';
												|it = 'Non installare';
												|pl = 'Nie ustawiać';
												|tr = 'Belirleme'"));
			
			AddlParameters = New Structure;
			AddlParameters.Insert("SelectedRows", 		SelectedRows);
			AddlParameters.Insert("StatusPresentation", 	StatusBar_.StatusPresentation);
			AddlParameters.Insert("StatusValueName", 		StatusBar_.StatusValueName);
			AddlParameters.Insert("List", 				List);
			AddlParameters.Insert("ListUpdateOptions", ListUpdateOptions);
			
			ShowQueryBox(New CallbackDescription("SetStatusCompletion", ThisObject, AddlParameters), QueryText,Mode);
		EndIf;
	EndIf;
	
EndProcedure

// Handler for an alert called after the Setstatus (...) procedure is completed.
Procedure SetStatusCompletion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	StatusPresentation = AdditionalParameters.StatusPresentation;
	StatusValueName = AdditionalParameters.StatusValueName;
	List = AdditionalParameters.List;
	ListUpdateOptions = AdditionalParameters.ListUpdateOptions;
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SetStatusCompletionFragment(SelectedRows, StatusValueName, StatusPresentation, List, Undefined, ListUpdateOptions);
	
EndProcedure

Procedure SetStatusCompletionFragment(Val SelectedRows, StatusValueName, Val StatusPresentation, Val List, AddlParameters = Undefined, ListUpdateOptions = Undefined)
	
	Var ProcessedItemsCount;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, StatusValueName, AddlParameters);
	TMCommonUseClient.NotifyUserAboutSettingStatus(List, ProcessedItemsCount, SelectedRows.Count(), StatusPresentation, ListUpdateOptions);

EndProcedure

// Handler for an alert called after the Setstatus (...) procedure is completed.
Procedure SetStatusImplementedCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	ProcessedList = AdditionalParameters.ProcessedList;
	StatusPresentation = AdditionalParameters.StatusPresentation;
	StatusValueName = AdditionalParameters.StatusValueName;
	ListUpdateOptions = AdditionalParameters.ListUpdateOptions;
	
	ResponseStructure = Result;
	If ResponseStructure = Undefined Then
		Return;
	EndIf;
	
	SetStatusCompletionFragment(SelectedRows, StatusValueName, StatusPresentation, ProcessedList, ResponseStructure, ListUpdateOptions);
	
EndProcedure

// Processes the scanned barcode
//
// Parameters:
//  Barcode			 - 	String -
//  BarcodeData	 - 	Structure - structure with a key of "Clozapine" register information Restraurants
//  Form				 - 	ClientApplicationForm - list form
//  ListName			 - 	String - name of the list to be positioned in.
//
Procedure ProcessBarcodes(Barcode, BarcodeData, Form, ListName) Export
	
	If ValueIsFilled(BarcodeData) Then
		If ValueIsFilled(BarcodeData.RecordKey) Then
			FormTable = Form.Items[ListName]; // FormTable - 
			FormTable.CurrentRow = BarcodeData.RecordKey;
		EndIf;
		ShowValue(Undefined, BarcodeData.Ref);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Barcode);
	EndIf;
	
EndProcedure

// Handler for the "Set delete mark" command called from the document form. Simulates a standard command.
//
// Parameters:
//  Form - ClientApplicationForm	- the form of the document
//
Procedure SetDeleteQuestionDocumentMark(Form)
	
	If Form.Object.Ref.IsEmpty() Then
		Return;
	EndIf; 
	
	IsNewDeletionMark = Not Form.Object.DeletionMark;
	
	QuestionTitle = NStr("vi = 'Thay đổi cờ xóa';
						|ru = 'Изменение пометки удаления';
						|en = 'Change deletion mark'; fa = 'Change deletion mark';
						|it = 'Modifica del contrassegno di cancellazione';
						|pl = 'Zmiana zaznaczenia do usunięcia';
						|tr = 'Silme işareti değişimi'");
	If IsNewDeletionMark Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đặt dấu xóa ""%1""?';
																					|ru = 'Пометить ""%1"" на удаление?';
																					|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
																					|it = 'Contrassegnare ""%1"" per cancellazione?';
																					|pl = 'Zaznaczyć ""%1"" do usunięcia?';
																					|tr = '""%1"" silinmek üzere işaretle?'"),Form.Object.Ref);
	Else
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Bỏ dấu xóa ""%1""?';
																					|ru = 'Снять с ""%1"" пометку на удаление?';
																					|en = 'Do you want to clear a deletion mark for ""%1""?'; fa = 'Do you want to clear a deletion mark for ""%1""?';
																					|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
																					|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
																					|tr = '""%1"" için silme işaretini kaldır?'"),Form.Object.Ref);
	EndIf; 
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("IsNewDeletionMark",IsNewDeletionMark);
	AdditionalParameters.Insert("DocumentPosted",Form.Object.Posted);
	AdditionalParameters.Insert("Form",Form);
	CallbackDescription = New CallbackDescription("SetDeleteQuestionDocumentMarkCompletion", ThisObject, AdditionalParameters);
	
	ShowQueryBox(CallbackDescription,QueryText,QuestionDialogMode.YesNo,60,,QuestionTitle);
	
EndProcedure

// Handler for notification of the response to the question about setting / unchecking the delete document mark
//
//	Parameters:
//		QuestionResult 		- DialogReturnCode 	- result of the answer to the question,
//		AdditionalParameters - Structure 			- advanced setting.
//
Procedure SetDeleteQuestionDocumentMarkCompletion(QuestionResult, AdditionalParameters) Export
	Var IsNewDeletionMark, DocumentPosted, Form;
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf; 
	
	If Not AdditionalParameters.Property("IsNewDeletionMark", IsNewDeletionMark) Then
		IsNewDeletionMark = False;
	EndIf; 
	If Not AdditionalParameters.Property("DocumentPosted", DocumentPosted) Then
		DocumentPosted = False;
	EndIf; 
	AdditionalParameters.Property("Form", Form);
	
	If IsNewDeletionMark And DocumentPosted Then
		WriteMode = DocumentWriteMode.UndoPosting;
	Else
		WriteMode = DocumentWriteMode.Write;
	EndIf; 
	
	Form.Object.DeletionMark = IsNewDeletionMark;
	
	WriteParameters = StructureOfObjectRecordParameters();
	WriteParameters.Insert("WriteMode",WriteMode);
	Try
		WriteObject(Form, WriteParameters);
	Except
		Form.Object.DeletionMark = Not IsNewDeletionMark;
		
		ErrorInfo = ErrorInfo();
		Brief1 = ErrorProcessing.ErrorDescriptionForUser(ErrorInfo);
		Raise Brief1;
	EndTry;
	
EndProcedure

// Performs document processing using a background task.
//
// Parameters:
//  List - DynamicList - list of documents.
//  FormName - String - The form in which the background processing of documents is implemented.
//
Procedure NavigateDocumentsInBackgroundTask(List, FormName) Export

	ClearMessages();
	SelectedRows = CheckGetLinksHighlightedInList(List);
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	Result = GeneralPurposeTMServerCall.LinksOfDocumentsForConducting(SelectedRows);
	
	If Result.HasItemsMarkedForDeletion And Result.ReferencesArrray.Count() = 1 Then
		MessageText = NStr("vi = 'Không thể kết chuyển chứng từ đã đặt dấu xóa';
							|ru = 'Помеченный на удаление документ не может быть проведен';
							|en = 'Document marked for deletion cannot be posted'; fa = 'Document marked for deletion cannot be posted';
							|it = 'Il documento segnato per l''eliminazione non può essere registrato';
							|pl = 'Zaznaczony na usunięcie nie może być zatwierdzony';
							|tr = 'Silinmek üzere işaretlenmiş bir belge gerçekleştirilemez'");
		ShowMessageBox(,MessageText);
	ElsIf Result.YouCanSpend Then
		FormParameters = New Structure("DocumentsList", Result.ReferencesArrray);
		OpenForm(FormName, FormParameters);
	EndIf; 
	
EndProcedure

// Notifies about the result of the background task.
// 
// Parameters:
//  ResultOfCarryingOut - Structure - Contains:
//		* HasErrors - Boolean -
//		* ErrorInfo - ErrorInfo, Undefined -
//	ActionInCaseOfError - String, CallbackDescription -
Procedure ReportResultInBackgroundTask(ResultOfCarryingOut, ActionInCaseOfError = Undefined) Export
	
	If ResultOfCarryingOut = Undefined Then
		Return;
	EndIf;
	
	If ResultOfCarryingOut.HasErrors Then
		
		If ResultOfCarryingOut.ErrorInfo <> Undefined And TypeOf(ResultOfCarryingOut.ErrorInfo) = Type("ErrorInfo") Then
			
			ErrorProcessing.ShowErrorInfo(ResultOfCarryingOut.ErrorInfo);
		
		Else
			
			If ActionInCaseOfError <> Undefined Then
				ExplanationText = NStr("vi = 'Khi kết chuyển, đã xảy ra lỗi (nhấp vào để xem)';
										|ru = 'При проведении возникли ошибки (нажмите для просмотра)';
										|en = 'Errors occurred while posting (click to view)'; fa = 'Errors occurred while posting (click to view)';
										|it = 'При проведении возникли ошибки (нажмите для просмотра)';
										|pl = 'Errors occurred while posting (click to view)';
										|tr = 'Kaydetme sırasında hatalar oluştu (görüntülemek için tıklayın)'");
			Else
				ExplanationText = NStr("vi = 'Khi kết chuyển, đã xảy ra lỗi';
										|ru = 'При проведении возникли ошибки';
										|en = 'Errors occurred while posting'; fa = 'Errors occurred while posting';
										|it = 'При проведении возникли ошибки';
										|pl = 'Errors occurred while posting';
										|tr = 'Kaydetme sırasında hatalar oluştu'");
			EndIf;
			
			NotificationPicture = PictureLib.Attention32;
			ShowUserNotification(, ActionInCaseOfError, ExplanationText, NotificationPicture);
			
		EndIf;
		
	Else
		
		ExplanationText = NStr("vi = 'Đã kết chuyển';
								|ru = 'Проведение выполнено';
								|en = 'Posted'; fa = 'ثبت‌شده';
								|it = 'Pubblicazione eseguita';
								|pl = 'Zatwierdzenie zostało wykonane';
								|tr = 'Kaydetme gerçekleştirildi'");
		NotificationPicture = PictureLib.CheckmarkGreen;
		ShowUserNotification(,, ExplanationText, NotificationPicture);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region ControlOfInconsistentChanges

// Called in document and reference forms when working with elements that depend on the status
// of inconsistent changes in the control mechanism.
//
// Parameters:
// 		Form - ClientApplicationForm - the form of an element or document.
// Returns:
// 		Boolean - a sign of failure to perform further actions.
Function WhenActingOnStatusDependentElement(Form) Export
	
	If Form.StructureOfActionsControlOfNonAgreedChanges = Undefined Then
		Return True;
	EndIf;
	
	If Form.StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected Then
		Return False;
	EndIf;
	
	Form.StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected = True;
	If CommonClientServer.HasAttributeOrObjectProperty(Form.Object, "Approved") Then
		Form.Object.Approved = False;
	EndIf;
	
	Return False;
	
EndFunction

// The service procedure.
//
Procedure MonitoringNonConsistentChangesCauseException(Form, Item) Export
	Raise NStr("vi = 'Lỗi nội bộ của hệ thống con kiểm soát thay đổi không nhất quán.';
				|ru = 'Внутренняя ошибка подсистемы контроля несогласованных изменений.';
				|en = 'Internal error of the subsystem for unapproved change control.'; fa = 'Internal error of the subsystem for unapproved change control.';
				|it = 'Errore interno del subsistema di controllo delle modifiche non concordate';
				|pl = 'Błąd wewnętrzny podsystemu kontroli nie uzgodnionych zmian.';
				|tr = 'Kararlaştırılmamış değişiklik kontrol alt sisteminin iç hatası.'");
EndProcedure

// Called in the forms of documents and reference books to refuse to change the value of the details.
// Called for actions with elements that depend on the status.
//
// Parameters:
// 	Form - ClientApplicationForm - element or document form
// 	Item - FormField - Form element
// 	ProcessedElements - Array - Service, contains an array of already processed elements
//
Procedure ReturnPreviousPropsValue(Form, Item, ProcessedElements = Undefined) Export
	
	If ProcessedElements = Undefined Then
		ProcessedElements = New Array;
	EndIf;
	
	TagName = Item.Name;
	Table = FieldInsideTable(Form, Item);
	If Not Table = Undefined Then
		TableName = Table.Name;
	Else
		TableName = "";
	EndIf;
	
	If Form.StructureOfActionsControlOfNonAgreedChanges <> Undefined Then
		
		If Not ValueIsFilled(TableName) Then
			If Not Form.StructureOfActionsControlOfNonAgreedChanges.AttributesValues.Property(TagName) Then
				Return;
			EndIf;
		EndIf;
		
	EndIf;
	
	DataPath = Form.StructureOfActionsControlOfNonAgreedChanges.DataPath[TagName];
	
	Array = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".");
	Data = Form;
	Count = Array.Count();
	IndexOf = 1;
	For Each ArrayRow In Array Do
		If TypeOf(Data) = Type("FormDataStructure") And IndexOf = Count Then
			Data[ArrayRow] = Form.StructureOfActionsControlOfNonAgreedChanges.AttributesValues[TagName];
		ElsIf TypeOf(Data) = Type("FormDataCollection") Then
			If Not Table.CurrentData = Undefined Then
				Table.CurrentData[ArrayRow] = Form.StructureOfActionsControlOfNonAgreedChanges.AttributesValues[TableName][ArrayRow];
			EndIf;
			Break;
		Else
			Data = Data[ArrayRow];
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	ChoiceParameterLinks = Form.StructureOfActionsControlOfNonAgreedChanges.ChoiceParameterLinks.Get(DataPath);
	If Not ChoiceParameterLinks = Undefined Then
		For Each RelationshipOfSelectionParameters In ChoiceParameterLinks Do
			If ProcessedElements.Find(RelationshipOfSelectionParameters) = Undefined Then
				ProcessedElements.Add(RelationshipOfSelectionParameters);
				ReturnPreviousPropsValue(Form, Form.Items[RelationshipOfSelectionParameters], ProcessedElements);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Invoked in the forms of documents and directories to save the previous value of the element.
// Called for actions with elements that depend on the status.
//
// Parameters:
// 	Form - ClientApplicationForm - element or document form
// 	Item - FormField - form element.
//
Procedure SaveAttributeValue(Form, Item) Export
	
	TagName = Item.Name;
	Table = FieldInsideTable(Form, Item);
	If Not Table = Undefined Then
		TableName = Table.Name;
	Else
		TableName = "";
	EndIf;
	
	If Form.StructureOfActionsControlOfNonAgreedChanges <> Undefined Then
		
		If ValueIsFilled(TableName) Then
			Return;
		Else
			If Not Form.StructureOfActionsControlOfNonAgreedChanges.AttributesValues.Property(TagName) Then
				Return;
			EndIf;
		EndIf;
		
	EndIf;
	
	DataPath = Form.StructureOfActionsControlOfNonAgreedChanges.DataPath[TagName];
	
	Array = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".");
	Data = Form;
	Count = Array.Count();
	IndexOf = 1;
	For Each ArrayRow In Array Do
		If TypeOf(Data) = Type("FormDataStructure") And IndexOf = Count Then
			Form.StructureOfActionsControlOfNonAgreedChanges.AttributesValues[TagName] = Data[ArrayRow];
		Else
			Data = Data[ArrayRow];
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

// Called in document and reference forms when working with elements that depend on the status
// of inconsistent changes in the control mechanism.
//
// Parameters:
// 	Form - ClientApplicationForm - the form of an element or document.
//
Procedure AfterChangingPropsDependentOnStatus(Form) Export
	
	Form.StructureOfActionsControlOfNonAgreedChanges = Undefined;
	
EndProcedure

#EndRegion

#Region NotifyingUsersWhenChangesOccur

// The procedure shows a notification after processing the statuses of the selected documents in the list.
//
// Parameters:
//	DocumentsList  - FormTable - Form element
//	ProcessedItemsCount - Number - number of successfully processed documents
//	TotalCount1 - Number - number of documents selected in the list
//	Status - String - Set Status
//	ListUpdateOptions - Undefined, Structure - update options:
//		* Form - ClientApplicationForm - The Form in which the list of documents is located
//		* ListName - String - the name of the dynamic list Attribute on the Form
//		* UpdateList - Boolean - indicates whether the list needs to be updated
//
Procedure NotifyUserAboutSettingStatus(DocumentsList, ProcessedItemsCount, TotalCount1, Status, ListUpdateOptions = Undefined) Export
	
	If ProcessedItemsCount > 0 Then
		
		If DocumentsList <> Undefined Then
			
			If ListUpdateOptions = Undefined Then
				UpdateList = True;
			Else
				UpdateList = ListUpdateOptions.UpdateList;
			EndIf;
			
			If UpdateList Then
				DocumentsList.Refresh();
			Else
				OperationsWithDocumentJournalsClient.SetFlagForDisplayingIrrelevantDataInList(
					ListUpdateOptions.Form, ListUpdateOptions.ListName);
			EndIf;
			
		EndIf;
		
		MessageText = NStr("vi = 'Đối với %ProcessedItemsCount% từ %TotalCount1% được chọn trong danh sách có trạng thái ""%Status%""';
							|ru = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке документов установлен статус ""%Status%""';
							|en = 'Status ""%Status%"" is set for %ProcessedItemsCount% out of %TotalCount1% documents selected in the list'; fa = 'Status ""%Status%"" is set for %ProcessedItemsCount% out of %TotalCount1% documents selected in the list';
							|it = 'Per %ProcessedItemsCount% da %TotalCount1% documenti selezionati nella lista dei documenti è impostato lo stato ""%Status%""';
							|pl = 'Dla %ProcessedItemsCount% z %TotalCount1% zaznaczonych w liście dokumentów jest określony status ""%Status%""';
							|tr = 'Belgeler listesinde seçilen %TotalCount1%''in %ProcessedItemsCount%''i için durum ""%Status%"" olarak ayarlanır'");
		MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", ProcessedItemsCount);
		MessageText = StrReplace(MessageText, "%TotalCount1%",        TotalCount1);
		MessageText = StrReplace(MessageText, "%Status%",                 Status);
		TitleText = NStr("vi = 'Trạng thái ""%Status%"" đã đặt';
						|ru = 'Статус ""%Status%"" установлен';
						|en = 'Status ""%Status%"" is set'; fa = 'Status ""%Status%"" is set';
						|it = 'Lo stato ""%Status%"" è impostato';
						|pl = 'Ustawiono status ""%Status%""';
						|tr = 'Durum ""%Status%"" ayarlandı'");
		TitleText = StrReplace(TitleText, "%Status%", Status);
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);

	Else
		
		MessageText = NStr("vi = 'Trạng thái ""%Status%"" không được đặt cho bất kỳ chứng từ nào.';
							|ru = 'Статус ""%Status%"" не установлен ни для одного документа.';
							|en = 'Status ""%Status%"" is not set for any document.'; fa = 'Status ""%Status%"" is not set for any document.';
							|it = 'Lo stato ""%Status%"" non è impostato per alcun documento.';
							|pl = 'Status ""%Status%"" nie jest określony dla żadnego dokumentu.';
							|tr = '""%Status%"" durumu herhangi bir belge için ayarlanmadı.'");
		MessageText = StrReplace(MessageText, "%Status%", Status);
		TitleText = NStr("vi = 'Trạng thái ""%Status%"" chưa đặt';
						|ru = 'Статус ""%Status%"" не установлен';
						|en = 'Status ""%Status%"" is not set'; fa = 'Status ""%Status%"" is not set';
						|it = 'Lo stato ""%Status%"" non è impostato';
						|pl = 'Nie ustawiono statusu ""%Status%""';
						|tr = 'Durum ""%Status%"" ayarlanmadı'");
		TitleText = StrReplace(TitleText, "%Status%", Status);
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

// The procedure notifies and records changes to the object in the user's history, as the platform does.
//
// Parameters:
//	ObjectReference       - AnyRef - changed object.
//	TitleText - String - Title text
Procedure NotifyUserAboutChangesToObject(ObjectReference, TitleText = "") Export
	
	If IsBlankString(TitleText) Then	
		TitleText = NStr("vi = 'Thay đổi:';
						|ru = 'Изменение:';
						|en = 'Editing:'; fa = 'Editing:';
						|it = 'Modifica:';
						|pl = 'Zmiana:';
						|tr = 'Değişim:'");
	EndIf;
	MessageText = String(ObjectReference);
	URL = GetURL(ObjectReference);
	ShowUserNotification(TitleText, URL, MessageText, PictureLib.Information32);

	UserWorkHistory.Add(URL);
	
EndProcedure

// Notifies the user when a mark is set to delete
// or unmark a document when it is deleted, and also records information about changes to the object in the history.
//
//	Parameters:
//		QuestionResult - DialogReturnCode - result of the answer to the question,
//		AdditionalParameters - Structure - advanced setting:
//			* List - FormTable - 
//			* ListType - String -
//			* SelectedRows - Array of DocumentRef - 
//			* SetMarkForDeletion - Boolean - 
//			* CallbackOnCompletion - CallbackDescription - 
//			* ListUpdateOptions - Undefined, Structure - 
Procedure SetDeletionMarkCompletion(QuestionResult, AdditionalParameters) Export
	
	CallbackOnCompletion = AdditionalParameters.CallbackOnCompletion;
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		ClearMessages();
		
		List = AdditionalParameters.List;
		ListType = AdditionalParameters.ListType;
		ReferencesArrray = AdditionalParameters.SelectedRows;
		MarkToDelete = AdditionalParameters.SetMarkForDeletion;
		ListUpdateOptions = AdditionalParameters.ListUpdateOptions;
		
		GeneralPurposeTMServerCall.SetDeletionMarkCompletionServer(ReferencesArrray, MarkToDelete);
		
		URL = Undefined;
		If ReferencesArrray.Count() > 1 Then
			Document = ListType;
			NotificationText1 = ?(Not MarkToDelete, 
				NStr("vi = 'Xóa dấu xóa (%DocumentsCount%)';
					|ru = 'Пометка удаления снята (%DocumentsCount%)';
					|en = 'Deletion mark is cleared (%DocumentsCount%)'; fa = 'Deletion mark is cleared (%DocumentsCount%)';
					|it = 'Il contrassegno per la cancellazione è stato rimosso (%DocumentsCount%)';
					|pl = 'Usunięto zaznaczenie usunięcia (%DocumentsCount%)';
					|tr = 'Silme işareti kaldırıldı (%DocumentsCount%)'"),
				NStr("vi = 'Đã đặt dấu xóa (%DocumentsCount%)';
					|ru = 'Пометка удаления установлена (%DocumentsCount%)';
					|en = 'Deletion mark is set (%DocumentsCount%)'; fa = 'Deletion mark is set (%DocumentsCount%)';
					|it = 'Il contrassegno per la cancellazione è stato impostato (%DocumentsCount%)';
					|pl = 'Ustawiono zaznaczenie usunięcia (%DocumentsCount%)';
					|tr = 'Silme işareti ayarlandı (%DocumentsCount%)'"));
			NotificationText1 = StrReplace(NotificationText1, "%DocumentsCount%", ReferencesArrray.Count());
		Else
			Document = ReferencesArrray[0];
			URL = GetURL(Document);
			NotificationText1 = ?(Not MarkToDelete,
				NStr("vi = 'Bỏ đặt dấu xóa';
					|ru = 'Пометка удаления снята';
					|en = 'Deletion mark is cleared'; fa = 'Deletion mark is cleared';
					|it = 'Il contrassegno per la cancellazione è stato rimosso';
					|pl = 'Usunięto zaznaczenie usunięcia';
					|tr = 'Silme işareti kaldırıldı'"),
				NStr("vi = 'Đã đặt dấu xóa';
					|ru = 'Пометка удаления установлена';
					|en = 'Deletion mark is set'; fa = 'Deletion mark is set';
					|it = 'Il contrassegno per la cancellazione è stato impostato';
					|pl = 'Ustawiono zaznaczenie usunięcia';
					|tr = 'Silme işareti ayarlandı '"));
		EndIf;
		
		If ListUpdateOptions <> Undefined Then
			UpdateList = ListUpdateOptions.UpdateList;
		Else
			UpdateList = True;
		EndIf;

		If UpdateList Then
			List.Refresh();
		Else
			OperationsWithDocumentJournalsClient.SetFlagForDisplayingIrrelevantDataInList(
					ListUpdateOptions.Form, ListUpdateOptions.ListName);
		EndIf;
		
		ShowUserNotification(NotificationText1, URL, String(Document),
			PictureLib.Information32);
		
	EndIf;
	
	If CallbackOnCompletion <> Undefined Then 
		RunCallback(CallbackOnCompletion, QuestionResult);
	EndIf;
	
EndProcedure

// Notifies the user about the completed execution or cancellation of the documents, as well as updates
// information about the changed data of the dynamic list.
//
// Parameters:
//	QuestionResult - Button - the result of the answer to the question.
//	AdditionalParameters - Structure - advanced setting:
//		* List - FormTable - form table.
//		* ListType - String - type of list documents.
//
Procedure CheckDocumentsPostingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> Undefined Then
		List = AdditionalParameters.List;
		ListType = AdditionalParameters.ListType;
		PostedDocuments = AdditionalParameters.PostedDocuments;
		ListUpdateOptions = AdditionalParameters.ListUpdateOptions;
		
		If PostedDocuments.Count() > 0 Then
			NotificationOfHoldingCancellationOfDocument(List, PostedDocuments, ListType, ListUpdateOptions);
		Else
			If ListUpdateOptions <> Undefined Then
				UpdateList = ListUpdateOptions.UpdateList;
			Else
				UpdateList = True;
			EndIf;
			
			If UpdateList Then
				List.Refresh();
			Else
				OperationsWithDocumentJournalsClient.SetFlagForDisplayingIrrelevantDataInList(
					ListUpdateOptions.Form,
					ListUpdateOptions.ListName);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Completion procedure for the vvestidatuscontrolempust Value().
// Notifies the user that the date was entered correctly. otherwise 
// , a message is displayed that the date value was not filled in and you are prompted to enter it again.
//
// Parameters:
//	SelectedDate - Date - the date value entered by the user as a result of the dialog.
//	AdditionalParameters - Structure - advanced setting.
//
Procedure EnterDateWithControlOfEmptyValueAfterSelection(SelectedDate, AdditionalParameters) Export
	
	If SelectedDate = Undefined Then
		RunCallback(AdditionalParameters.ChoiceNotification1, Undefined);
	Else
		If SelectedDate <> Date('00010101000000') Then
			RunCallback(AdditionalParameters.ChoiceNotification1, SelectedDate);
		Else
			Notification = New CallbackDescription("EnterDateWithControlOfEmptyValueAfterWarning", ThisObject,
				AdditionalParameters);
			ShowMessageBox(Notification, NStr("vi = 'Chưa điền trường ""Ngày""';
												|ru = 'Поле ""Дата"" не заполнено';
												|en = '""Date"" is required'; fa = '""Date"" is required';
												|it = 'Il campo ""Data"" non è compilato';
												|pl = 'Pole ""Дата"" nie jest wypełnione';
												|tr = '""Tarih"" alanı doldurulmadı'"));
		EndIf;
	EndIf;

EndProcedure

// The End procedure for the data check of the Empty value after the selection().
// Notifies the user that the date value has not been filled in and is prompted to re-enter.
//
// Parameters:
//	AdditionalParameters - Structure - advanced setting.
//
Procedure EnterDateWithControlOfEmptyValueAfterWarning(AdditionalParameters) Export
	
	EnterDateWithControlOfEmptyValue(AdditionalParameters.Date, AdditionalParameters.ToolTip,
		AdditionalParameters.DatePart, AdditionalParameters.ChoiceNotification1);
	
EndProcedure

//The procedure shows a message about exceeding the amount in the document when calling the form "Checking the filling of documents"
//
// Parameters:
//  ReturnParameters - Structure - the structure of the returned parameters from the general form "Document fill-in check" 
//  BaseText - String - Order Restrictions
//
Procedure DisplayMessageExceedingNumber(ReturnParameters, BaseText = "") Export

	If TypeOf(ReturnParameters) = Type("Structure")
			And ReturnParameters.Property("ExceedingIsProhibited")
			And ReturnParameters.ExceedingIsProhibited = True Then
		
		TextTemplate1 = NStr("vi = 'Không xem xét vượt quá số lượng đối với chứng từ %1';
							|ru = 'Превышение количества не предусмотрено для документа %1';
							|en = 'Quantity excess is not allowed for the %1 document'; fa = 'Quantity excess is not allowed for the %1 document';
							|it = 'Превышение количества не предусмотрено для документа %1';
							|pl = 'Quantity excess is not allowed for the %1 document';
							|tr = '%1 belgesi için fazla miktar sağlanmamış'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, BaseText);
		CommonClient.MessageToUser(MessageText);
	EndIf; 

EndProcedure

#EndRegion

#Region EditingBlockedBankingDetails

// Invoked in the forms of objects to unlock a locked account details.
// 
// Parameters:
//	Form - ClientApplicationForm - object form:
//     	* Object - DocumentObject -
//	Parameters - See PermissionParametersForEditingItemDetails
//
Procedure AllowObjectAttributeEdit(Form, Parameters = Undefined) Export
	
	If Parameters = Undefined Then
		Parameters = PermissionParametersForEditingItemDetails();
	EndIf;
	
	ObjectDetails = ?(Parameters.Object = Undefined, Form.Object, Parameters.Object);
	
	If Not ValueIsFilled(ObjectDetails.Ref) Then
		Return;
	EndIf;
	
	NameOfUnlockForm = Parameters.NameOfUnlockForm;
	
	If Not ValueIsFilled(NameOfUnlockForm) Then
		FormNameArray1 = StringFunctionsClientServer.SplitStringIntoWordArray(Form.FormName, ".");
		FormNameArray1[3] = "AttributeUnlocking";
		NameOfUnlockForm = StrConcat(FormNameArray1, ".");
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",Form);
	AdditionalParameters.Insert("OnlyVisible", Parameters.OnlyVisible);
	If Parameters.NotificationAboutUnblocking <> Undefined Then
		AdditionalParameters.Insert("NotificationAboutUnblocking", Parameters.NotificationAboutUnblocking);
	EndIf; 
	
	Notification = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(NameOfUnlockForm, 
		New Structure("Object, AttributeEditProhibitionParameters", ObjectDetails.Ref, Form.AttributeEditProhibitionParameters),
		,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters for the permission to edit the details of the object.
// 
// Returns:
//  Structure - Permission Parameters For Editing Item Details:
// 		* NameOfUnlockForm - String - Name of the unlock form.
// 		* NotificationAboutUnblocking - CallbackDescription, Undefined -
// 		* Object - Undefined - take an object from the props of the "Object" form",
//               - FormDataStructure - by object type.
// 		* OnlyVisible - Boolean - to get and unlock all the details of the object, you need to specify a Lie.
Function PermissionParametersForEditingItemDetails() Export
	
	Parameters = New Structure;
	Parameters.Insert("NameOfUnlockForm", "");
	Parameters.Insert("NotificationAboutUnblocking", Undefined);
	Parameters.Insert("Object", Undefined);
	Parameters.Insert("OnlyVisible", True);
	
	Return Parameters;
	
EndFunction

// The service procedure.
//
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	If Result = True Then
		
		OnlyVisible = True;
		If AdditionalParameters.Property("OnlyVisible") Then
			OnlyVisible = AdditionalParameters.OnlyVisible;
		EndIf;
		
		LockedAttributes = ObjectAttributesLockClient.Attributes(Form,, OnlyVisible);
		ObjectAttributesLockClient.SetAttributeEditEnabling(Form, LockedAttributes);
		ObjectAttributesLockClient.SetFormItemEnabled(Form);
		
	EndIf;
	
	If AdditionalParameters.Property("NotificationAboutUnblocking") Then
		
		RunCallback(AdditionalParameters.NotificationAboutUnblocking, Result);
		
	EndIf; 

EndProcedure

#EndRegion

#Region OtherItems

// Performed when the user interactively starts working with the data area or in local mode.
// Corresponds to the handler for the system's Initialerabout.
//
// See CommonClientOverridable.OnStart 
//
Procedure OnStart(Parameters) Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientRunParameters.OpenNotificationAboutOutdatedFunctionality Then
		OpenForm("DataProcessor.TransitionReadiness26.Form.NotificationForm26",,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
	If ClientRunParameters.AskQuestionAboutSwitchingToOnlineSettlements Then
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Có';
												|ru = 'Да';
												|en = 'Yes'; fa = 'بله';
												|it = 'Sì';
												|pl = 'Yes';
												|tr = 'Evet'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Không phải bây giờ';
												|ru = 'Не сейчас';
												|en = 'Maybe later'; fa = 'Maybe later';
												|it = 'Non ora';
												|pl = 'Nie teraz';
												|tr = 'Şimdi değil'"));
		Buttons.Add(DialogReturnCode.Abort, NStr("vi = 'Không';
												|ru = 'Нет';
												|en = 'No'; fa = 'خیر';
												|it = 'No';
												|pl = 'No';
												|tr = 'Hayır'"));
		ResponseHandler1 = New CallbackDescription("CompletingTransitionQuestion", TMCommonUseClient);
		QueryText = NStr("vi = 'Nên chuyển đến chế độ hạch toán công nợ «trực tuyến» mới. 
			|Điều này giúp đẩy nhanh việc in chứng từ và mở ra tính năng mới trong báo cáo. 
			|Thực hiện chuyển đổi?';
			|ru = 'Рекомендуется перейти на новый режим «онлайн» учета взаиморасчетов. 
			|Это ускорит печать документов и откроет новые возможности в отчетах. 
			|Выполнить переход?';
			|en = 'Switching to the new online settlements accounting mode is recommended. 
			|This will speed up printing of documents and unlock new features in reports. 
			|Do you want to switch?'; fa = 'Switching to the new online settlements accounting mode is recommended. 
			|This will speed up printing of documents and unlock new features in reports. 
			|Do you want to switch?';
			|it = 'Si consiglia di passare alla modalita ""online"" di registrazione di pagamenti reciproci. 
			| Questa modalità velocizzerà la stampa dei documenti e attiverà nuove funzionalità nei report. 
			|Eseguire il passaggio?';
			|pl = 'Zaleca się przejść do nowego trybu ewidencji rozliczeń wzajemnych ""online"". 
			|To przyśpieszy drukowanie dokumentów i otworzy nowe możliwości w raportach. 
			|Wykonać przejście?';
			|tr = 'Mutabakatlar için yeni ""çevrimiçi"" muhasebe moduna transfer edilmesi önerilmektedir. 
			|Bu, belgelerin yazdırılmasını hızlandıracak ve raporlarda yeni fırsatlar yaratacaktır. 
			|Transfer et?'");
		ShowQueryBox(ResponseHandler1, QueryText, Buttons);
	EndIf;
	
	UserNotificationsOfEventsClient.OnStart(Parameters);
	
	#If MobileClient Then
		If ExchangeMobilePCCall.OfflineModeIsAvailable() Then
			ExchangeMobileOfflineClient.CreateExchangeNode();
		EndIf;
		
		If ExchangeMobilePCCall.RequiresDataExchangeWithStandaloneApplication(ExchangeMobileOfflineClient.CurrentNode()) Then
			If MainServerAvailable() = True Then
				ExchangeMobileOfflineClient.StartExchange();
			EndIf;
			AttachIdleHandler("CheckingNeedForSynchronization", 10);
		EndIf;
	#EndIf
	
EndProcedure

// See CommonClientOverridable.OnGlobalSearch
Procedure OnGlobalSearch(SearchString, SearchPlan) Export
	
	SearchPlan.Add("FindDocumentInRegistry", "TMCommonUse", True, , 5);
	
EndProcedure

// Processes the response to the question about switching to new settlements
//
// Parameters:
// 	Result - DialogReturnCode
// 	AdditionalParameters - Structure
//
Procedure CompletingTransitionQuestion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		HomePage = GetWindows()[1];
		FormOwner = Undefined;
		If HomePage.Content.Count() > 0 Then
			FormOwner = HomePage.Content[0];
		EndIf;
		OpenForm("CommonForm.FormOfMigrationToOnlineARAPAccounting",,FormOwner);
		
	ElsIf Result = DialogReturnCode.Abort Then
		ARAPAccountingServerCall.DisableIssueOfSwitchingToOnlineSettlements();
	EndIf;
	
EndProcedure

// Checks for selected rows in the list.
//
// Parameters:
//	List - DynamicList - a list that is checked for the presence of selected lines.
//
// Returns:
//	Boolean - False - there are no highlighted lines in the list.
//
Function CheckForSelectedLinesInList(List) Export
	
	HasData = False;
	
	For Iterator_SSLy = 0 To List.SelectedRows.UBound() Do
		If TypeOf(List.SelectedRows[Iterator_SSLy]) <> Type("DynamicListGroupRow") Then
			RowData = List.RowData(List.SelectedRows[Iterator_SSLy]);
			
			If RowData = Undefined Then
				Continue;
			EndIf;
			
			HasData = True;
			
			Break;
		EndIf;
	EndDo;
	
	If Not HasData Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
								|ru = 'Команда не может быть выполнена для указанного объекта!';
								|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
								|it = 'Il comando non può essere eseguito per oggetto indicato!';
								|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
								|tr = 'Komut belirtilen nesne için gerçekleştirilemez!'"));
	EndIf;
	
	Return HasData;
	
EndFunction

// Checks for selected rows in the list and returns an array of their references.
//
// Parameters:
//	List - DynamicList - a list that is checked for the presence of selected lines.
//
// Returns:
//	Array of AnyRef, FormDataStructure, FormDataCollectionItem, FormDataTreeItem - an array of links highlighted in the list of strings.
//
Function CheckGetLinksHighlightedInList(List) Export
	
	ReferencesArrray = New Array;
	
	For Iterator_SSLy = 0 To List.SelectedRows.UBound() Do
		If TypeOf(List.SelectedRows[Iterator_SSLy]) <> Type("DynamicListGroupRow") Then
			RowData = List.RowData(List.SelectedRows[Iterator_SSLy]);
			
			If RowData = Undefined Then
				Continue;
			EndIf;
			
			If TypeOf(List.SelectedRows[Iterator_SSLy]) = Type("DynamicListRowKey") Then
				ReferencesArrray.Add(RowData);
			Else
				ReferencesArrray.Add(List.SelectedRows[Iterator_SSLy]);
			EndIf;
		EndIf;
		
	EndDo;
	
	If ReferencesArrray.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
								|ru = 'Команда не может быть выполнена для указанного объекта!';
								|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
								|it = 'Il comando non può essere eseguito per oggetto indicato!';
								|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
								|tr = 'Komut belirtilen nesne için gerçekleştirilemez!'"));
	EndIf;
	
	Return ReferencesArrray;
	
EndFunction

// Checks for entries in the list.
//
// Parameters:
//	List - DynamicList - a list that is checked for the presence of selected lines.
//	ListPresentation - DynamicList - a list that is checked for the presence of selected lines.
//
// Returns:
//	Boolean - True - the list contains entries.
//
Function CheckForRowsInList(List, ListPresentation) Export
	
	If List.Count() = 0 Then
		MessageText = NStr("vi = 'Không một dòng nào được nhập vào danh sách ""%ListPresentation%""';
							|ru = 'Не введено ни одной строки в список ""%ListPresentation%""';
							|en = 'No line is entered into the ""%ListPresentation%"" list'; fa = 'No line is entered into the ""%ListPresentation%"" list';
							|it = 'Non è inserita alcuna riga nell''elenco ""%ListPresentation%""';
							|pl = 'Nie wprowadzono żadnego wiersza do listy ""%ListPresentation%""';
							|tr = '""%ListPresentation%"" listesine hiç bir satır girilmedi'");
		MessageText = StrReplace(MessageText, "%ListPresentation%", ListPresentation);
		ShowMessageBox(, MessageText);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether the order is selected for processing the invoice
//
// Parameters:
//  CurLines_		 - 	FormDataStructure, Array - an array of IDs of the selected rows, or the current data of the selected row.
//  LogParameters	 - 	Structure - structure with log (workplace) parameters.
// 
// Returns:
//  Boolean - True
//
Function SelectedDocumentsForRegistration(CurLines_, LogParameters) Export
	
	If Not TypeOf(CurLines_) = Type("Array") Then
		RowsArray = New Array;
		If Not CurLines_ = Undefined Then
			RowsArray.Add(CurLines_);
		EndIf;
	Else
		RowsArray = CurLines_;
	EndIf;
	
	If Not RowsArray.Count() = 0 Then
		Return True;
	EndIf;
	
	ShowQuestionNotSelected(LogParameters);
	
	Return False;
	
EndFunction

// Opens the processing (log) form)
//
// Parameters:
//  Parameters	 - Structure	 - a structure with one of the keys "Workname".
//
Procedure OpenLog(Parameters) Export
	
	OpenForm("DataProcessor." + Parameters.WorkplaceName + ".Form", Parameters);
	
EndProcedure

// Saves the data necessary for the operation of the mechanism in the details of the form's cache data.
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// 	MechanismName - String - The name of the mechanism that stores the data
// 	DataToCache - Arbitrary - Cached data
//
Procedure SaveEngineDataToFormCache(Form, MechanismName, DataToCache) Export
	
	If Not CommonClientServer.HasAttributeOrObjectProperty(Form, "MechanismDataCache") Then
		AttributesToBeAdded = New Array;
		AttributesToBeAdded.Add(Form.MechanismDataCache);
		Form.ChangeAttributes(AttributesToBeAdded);
		Form.MechanismDataCache = New Structure;
	EndIf;
	Form.MechanismDataCache.Insert(MechanismName, DataToCache);
	
EndProcedure

// Returns parameters for Transferring to the general form of the question response
// 
// Returns:
//  Structure - structure with fields:
//   * QueryText - String - question text
//   * ButtonsList - ValueList of String - list of buttons.
//   * QuestionTitle - String - Heading.
//   * ShowCloseButton - Boolean - there is a window closure.
//
Function FormParametersQuestionYesNoCancel() Export
	
	Result = New Structure();
	Result.Insert("QueryText", "");
	Result.Insert("ButtonsList", New ValueList());
	Result.Insert("QuestionTitle", "");
	Result.Insert("ShowCloseButton", True);
	Return Result;
	
EndFunction

#Region ObjectsRecord

// Record an object and measure the duration of its recording.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which this function is called.
//  HaveQuestionsBeforeRecording - Boolean - True if questions can be displayed to the user when recording.
//  ActionAfterRecording - CallbackDescription - handler that is executed after the object is written.
//
Procedure Write(Form, HaveQuestionsBeforeRecording = False, ActionAfterRecording = Undefined) Export
	
	WriteParameters = StructureOfObjectRecordParameters();
	WriteParameters.HaveQuestionsBeforeRecording = HaveQuestionsBeforeRecording;
	
	If ActionAfterRecording <> Undefined Then
		WriteParameters.Insert("ActionAfterRecording", ActionAfterRecording);
	EndIf;
	
	WriteObject(Form, WriteParameters);
	
EndProcedure

// Record an object, measure the duration of its recording, and close the object form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which this function is called.
//  HaveQuestionsBeforeRecording - Boolean - True if questions can be displayed to the user when recording.
//  ActionAfterRecording - CallbackDescription - handler that is executed after the object is written.
//
Procedure WriteAndClose(Form, HaveQuestionsBeforeRecording = False, ActionAfterRecording = Undefined) Export
	
	WriteParameters = StructureOfObjectRecordParameters();
	WriteParameters.HaveQuestionsBeforeRecording = HaveQuestionsBeforeRecording;
	
	If ActionAfterRecording <> Undefined Then
		WriteParameters.Insert("ActionAfterRecording", ActionAfterRecording);
	EndIf;
	
	WriteObjectAndClose(Form, WriteParameters);
	
EndProcedure

// Hold the document and measure the duration of its execution.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which this function is called.
//  HaveQuestionsBeforeRecording - Boolean - True if questions can be displayed to the user when recording.
//  ActionAfterRecording - CallbackDescription - handler that is executed after the object is written.
//
Procedure Post(Form, HaveQuestionsBeforeRecording = False, ActionAfterRecording = Undefined) Export
	
	WriteParameters = StructureOfObjectRecordParameters();
	WriteParameters.HaveQuestionsBeforeRecording = HaveQuestionsBeforeRecording;
	WriteParameters.WriteMode = DocumentWriteMode.Posting;
	
	If ActionAfterRecording <> Undefined Then
		WriteParameters.Insert("ActionAfterRecording", ActionAfterRecording);
	EndIf;
	
	WriteObject(Form, WriteParameters);
	
EndProcedure

// To pass a document to measure the duration of the event and close the form document.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which this function is called.
//  HaveQuestionsBeforeRecording - Boolean - True if questions can be displayed to the user during the session.
//  ActionAfterRecording - CallbackDescription - handler that is executed after the object is written.
//
Procedure PostAndClose(Form, HaveQuestionsBeforeRecording = False, ActionAfterRecording = Undefined) Export
	
	WriteParameters = StructureOfObjectRecordParameters();
	WriteParameters.HaveQuestionsBeforeRecording = HaveQuestionsBeforeRecording;
	WriteParameters.WriteMode = DocumentWriteMode.Posting;
	
	If ActionAfterRecording <> Undefined Then
		WriteParameters.Insert("ActionAfterRecording", ActionAfterRecording);
	EndIf;
	
	WriteObjectAndClose(Form, WriteParameters);
	
EndProcedure

// Set document deletion tag, simulates the standard document deletion tag command.
//
// Parameters:
//  Form - ClientApplicationForm - The Form Of the document in which this function is called:
//  	* Object - DocumentObject -
//
Procedure SetDeletionMarkForADocument(Form) Export
	
	If Form.Object.Ref.IsEmpty() Then
		Return;
	EndIf; 
	
	SetDeleteQuestionDocumentMark(Form);
	
EndProcedure


// Writes a document in the form
//
// Parameters:
//  Form - ManagedFormExtensionForObjects - The Form Of the document in which this function is called:
//  	* Object - DocumentObject -
//	WriteParameters - Structure - 
//
Function WriteObject(Form, WriteParameters)
	
	Var Posted, ActionAfterRecording;
	
	ClearMessages();
	
	If Not WriteParameters.HaveQuestionsBeforeRecording Then
		If Not Form.Object.Property("Posted", Posted) Then
			Posted =  False;
		EndIf;
		
		If Posted And WriteParameters.WriteMode = DocumentWriteMode.Write Then
			WriteParameters.WriteMode = DocumentWriteMode.Posting;
		EndIf;
		
		StartMeasuringObjectRecordingTime(Form, WriteParameters);
	Else
		If CommonClientServer.HasAttributeOrObjectProperty(Form, "ForceCloseTheForm") Then
			Form.ForceCloseTheForm = WriteParameters.ForceCloseTheForm;
		EndIf;
	EndIf;
	
	If WriteParameters.Property("ActionAfterRecording", ActionAfterRecording) Then
		WriteParameters.Delete("ActionAfterRecording");
	EndIf;
	
	Result = Form.Write(WriteParameters);
	
	If ActionAfterRecording <> Undefined Then
		If Result Then
			RunCallback(ActionAfterRecording, Result);
		EndIf;
		
		WriteParameters.Insert("ActionAfterRecording", ActionAfterRecording);
	EndIf;
	
	Return Result;
	
EndFunction

// Writes a document in the form
//
// Parameters:
//  Form - ClientApplicationForm - The Form Of the document in which this function is called:
//  	* Object - DocumentObject -
//	WriteParameters - Structure - 
//
Procedure WriteObjectAndClose(Form, WriteParameters)
	
	WriteParameters.ForceCloseTheForm = True;
	ClearMessages();
	
	If WriteParameters.HaveQuestionsBeforeRecording Then
		WriteParameters.NewObject = Not ValueIsFilled(Form.Object.Ref);
		Form.ForceCloseTheForm = WriteParameters.ForceCloseTheForm;
		Form.Write(WriteParameters);
	Else
		If WriteObject(Form, WriteParameters) Then
			Form.Close();
		EndIf;
	EndIf;
	
EndProcedure

Function StructureOfObjectRecordParameters()
	
	WriteParameters = New Structure;
	
	WriteParameters.Insert("HaveQuestionsBeforeRecording", False);
	WriteParameters.Insert("NewObject", False);
	WriteParameters.Insert("ForceCloseTheForm", False);
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Write);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
	
	Return WriteParameters;
	
EndFunction

Procedure StartMeasuringObjectRecordingTime(Form, WriteParameters)
	
	Var ForceCloseTheForm;
	Var WriteMode;
	
	If Not WriteParameters.Property("ForceCloseTheForm", ForceCloseTheForm) Then
		ForceCloseTheForm = False;
	EndIf;
	
	If Not WriteParameters.Property("WriteMode", WriteMode) Then
		WriteMode = DocumentWriteMode.Write;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Write And Not ForceCloseTheForm Then
		KeyOperationTemplate = "Write.%1";
	ElsIf WriteMode = DocumentWriteMode.Write And ForceCloseTheForm Then
		KeyOperationTemplate = "WriteAndClose.%1";
	ElsIf WriteMode = DocumentWriteMode.Posting And Not ForceCloseTheForm Then
		KeyOperationTemplate = "Post.%1";
	ElsIf WriteMode = DocumentWriteMode.Posting And ForceCloseTheForm Then
		KeyOperationTemplate = "PostAndClose.%1";
	ElsIf WriteMode = DocumentWriteMode.UndoPosting And Not ForceCloseTheForm Then
		KeyOperationTemplate = "CancelPosting.%1";
	ElsIf WriteMode = DocumentWriteMode.UndoPosting And ForceCloseTheForm Then
		KeyOperationTemplate = "CancelAndClose_.%1";
	EndIf;
	
	KeyOperationName = StrTemplate(KeyOperationTemplate, Form.FormName);
	PerformanceMonitorClient.TimeMeasurement(KeyOperationName);
	
EndProcedure

#EndRegion

// Opens the form after checking that the data in the owner form has not been modified
//  If the data is modified , a question is asked and the data is recorded in the owner form.
//  Then the form opens.
//
// Parameters:
//  FormName - String -
//  FormParameters  - Structure -
//  OwnerForm - ClientApplicationForm - 
//  FormOpeningMode - String - the default value is " Independent"
//  ParameterNameLink - String - if the parameter is passed, a reference
//                                     to the recorded document is placed in the form Parameters after drawing the object document from the owner Form.
//
Procedure OpenFormAfterCheckingPostingDocument(FormName, FormParameters, OwnerForm, FormOpeningMode = "Independent", ParameterNameLink = "") Export
	
	AdditionalParameters = AdditionalParametersForProcessingFormOpeningAfterCheckingDocumentCompletion();
	AdditionalParameters.FormName = FormName;
	
	CommonClientServer.SupplementStructure(
		AdditionalParameters.FormParameters,
		FormParameters,
		True);
	
	AdditionalParameters.OwnerForm = OwnerForm;
	AdditionalParameters.ParameterNameLink = ParameterNameLink;
	
	If Upper(FormOpeningMode) =  Upper("Independent") Then	
		AdditionalParameters.Insert("FormWindowOpeningMode", FormWindowOpeningMode.Independent);
		
	ElsIf  Upper(FormOpeningMode) = Upper("LockOwnerWindow") Then
		AdditionalParameters.Insert("FormWindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf  Upper(FormOpeningMode) =  Upper("LockWholeInterface") Then
		AdditionalParameters.Insert("FormWindowOpeningMode", FormWindowOpeningMode.LockWholeInterface);
		
	Else
		ExceptionText = NStr("vi = 'Giá trị tham số chưa xác định %1';
							|ru = 'Неизвестное значение параметра %1';
							|en = 'Unknown value of the %1 parameter'; fa = 'Unknown value of the %1 parameter';
							|it = 'Valore sconosciuto del parametro %1';
							|pl = 'Nieznana wartość parametru %1';
							|tr = '%1 parametresi için bilinmeyen değer'");
		ExceptionText = StrTemplate(ExceptionText, "FormOpeningMode");
		Raise ExceptionText;
	EndIf;
	
	CallbackDescription = New CallbackDescription("OpenFormAfterCheckingPostingDocumentCompletion", ThisObject, AdditionalParameters);
	
	ProcessNotificationAfterCheckingWhetherDocumentWasCompleted(OwnerForm, CallbackDescription);
	
EndProcedure

// Checks whether the document is modified or not. If not conducted or modified
// asks the user a question and conducts the document in the form. Then the notification is executed.
// In the result of the notification, a link to the document is placed.
//
// Parameters:
//  Form		 - ClientApplicationForm 
//  Notification	 - CallbackDescription 
//
Procedure ProcessNotificationAfterCheckingWhetherDocumentWasCompleted(Form, Notification) Export
	
	If Not ValueIsFilled(Form.Object.Ref)
		Or Not Form.Object.Posted
		Or Form.Modified Then
		
		AdditionalParameters = New Structure("Notification, Form", Notification, Form);
		IssueNotification = New CallbackDescription(
			"ProcessNotificationAfterCheckingWhetherDocumentWasCompletedCompletion",
			ThisObject, AdditionalParameters);
		
		QueryText = NStr("vi = 'Để tiếp tục, bạn phải kết chuyển chứng từ. Kết chuyển?';
						|ru = 'Для продолжения необходимо провести документ. Провести?';
						|en = 'Post the document to continue. Post?'; fa = 'Post the document to continue. Post?';
						|it = 'Per continuare è necessario registrare il documento. Registrare?';
						|pl = 'Aby kontynuować, należy zatwierdzić dokument. zatwierdzić?';
						|tr = 'Devam etmek için belgenin kaydedilmesi gerekir. Kaydedilsin mi?'");
		ShowQueryBox(IssueNotification, QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	RunCallback(Notification, Form.Object.Ref);
	
EndProcedure

#EndRegion

#Region UniversalEventHandlers

// Universal handler for changing Bank details
//
// Parameters:
//  Form					 - ClientApplicationForm - form where the handler is executed
//  AttributeName			 - String, Array of String	 - name of the item to process
//  ServerCallRequired_	 - Boolean			 - indicates whether the server needs to be called
//  ProcessingParameters		 - Structure		 - additional processing parameters
//
Procedure ContinueChangingProps(Form, AttributeName = "", ServerCallRequired_ = False, Val ProcessingParameters = Undefined) Export
	
	If ProcessingParameters = Undefined Then
		ProcessingParameters = New Structure;
	EndIf;
	
	NotificationParameters = New Structure("ServerCallRequired_, ProcessingParameters", ServerCallRequired_, ProcessingParameters);
	CallbackDescription = New CallbackDescription("AtEndOfChangingLocalizationDetails", Form, NotificationParameters);
	
	RunCallback(CallbackDescription, AttributeName);
	
EndProcedure

// Universal command handler of the form
//
// Parameters:
//  Form					 - ClientApplicationForm	 - form where the handler is executed
//  CommandName				 - String, Array	 - name of the command to run
//  ServerCallRequired_	 - Boolean			 - indicates whether the server needs to be called
//  ProcessingParameters		 - Structure		 - additional processing parameters
//
Procedure ContinueCommandExecution(Form, CommandName = "", ServerCallRequired_ = False, Val ProcessingParameters = Undefined) Export
	
	If ProcessingParameters = Undefined Then
		ProcessingParameters = New Structure;
	EndIf;
	
	NotificationParameters = New Structure("ServerCallRequired_, ProcessingParameters", ServerCallRequired_, ProcessingParameters);
	CallbackDescription = New CallbackDescription("ContinueRunningLocalizationCommand", Form, NotificationParameters);
	
	RunCallback(CallbackDescription, CommandName);
	
EndProcedure

#EndRegion

#Region MethodsOfWorkingWithRequest

// Adds a selection setting for queries to the collection 
//
// Parameters:
//  Filter               - Map of Structure - collection of selection settings
//  LeftValue       - String       - left selection value in queries
//  RightValue      - String       - right-the value of the selection in queries
//  TypeOfRequestComparison - String       - query comparison type, by default: "In"
//
Procedure AddSelectionItemToCollection(Filter, LeftValue, RightValue, TypeOfRequestComparison = "") Export
	
	TMCommonUseClientServer.AddSelectionItemToCollection(Filter, LeftValue, RightValue, TypeOfRequestComparison);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region WorkingWithRegistrationPeriod

// Returns a string representation of the period.
//
// Parameters:
//  RegistrationPeriod - Date   - Date within the month or quarter, the performance of which is necessary to obtain
//  CalendarPeriod - String - "Month" or "Quarter".
//
// Returns:
//  String - Representation of the month or quarter within which the Registration period value is located.
//
Function GetPresentationOfRegistrationPeriod(RegistrationPeriod, CalendarPeriod = "Month") Export
	
	Return TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(RegistrationPeriod, CalendarPeriod);
	
EndFunction

// Increases or decreases the period value by one value.
//
// Parameters:
//  Direction                     - Number  - "1" if we step to the next month, "-1" if we step to the previous month
//  StandardProcessing            - Boolean - a sign of the standard event processing
//  RegistrationPeriod               - Date   - Variable that the value of the next or previous month is placed in
//  RegistrationPeriodPresentation - String - Representation of the month of the registration Period.
//
Procedure RegulationOfPresentationOfRegistrationPeriod(Direction, StandardProcessing, RegistrationPeriod, RegistrationPeriodPresentation) Export

	StandardProcessing = False;

	If Direction = 1 Then
		RegistrationPeriod = EndOfMonth(RegistrationPeriod) + 1;
	ElsIf Direction = -1 Then
		RegistrationPeriod = BegOfMonth(RegistrationPeriod - 1);
	EndIf;

	RegistrationPeriodPresentation = GetPresentationOfRegistrationPeriod(RegistrationPeriod);

EndProcedure

// Selects a period from the list of possible periods.
//
// Parameters:
//  Item - FormField - The field of the form where the "start Selection" event occurs.
//  StandardProcessing - Boolean     - a sign of the standard event processing
//  RegistrationPeriod - Date       - Variable that the selected value is placed in
//  Form - ClientApplicationForm - Controlled form in which the event occurs "the Beginning of the selection"
//  ChoiceNotification1 - CallbackDescription - Description of the period selection notification
//  InitialValue - Date - Start date for selecting the period
//  CalendarPeriod - String - "Month" or "Quarter" - period step.
//
Procedure StartSelectingRegistrationPeriodPresentation(Item, StandardProcessing, RegistrationPeriod, Form, ChoiceNotification1, InitialValue = Undefined, CalendarPeriod = "Month") Export

	StandardProcessing = False;

	If InitialValue = Undefined Then
		InitialValue = RegistrationPeriod;
	EndIf;

	ChoiceList = New ValueList;
	BeginningOfCurYear = BegOfYear(InitialValue);
	BeginningOfLastYear = BegOfYear(BeginningOfCurYear - 1);
	ChoiceList.Add(BeginningOfLastYear, (Format(BeginningOfLastYear, NStr("vi = 'ДФ=''гггг''';
																			|ru = 'ДФ=''yyyy''';
																			|en = 'DF=''yyyy'''; fa = 'DF=''yyyy''';
																			|it = 'ДФ=''гггг''';
																			|pl = 'DF=''yyyy''';
																			|tr = 'ДФ=''гггг'''")) + "..."));
	StartOfFillingPeriod = BeginningOfCurYear;
	DefaultElement = Undefined;
	
	If CalendarPeriod = "Month" Then
		NumberOfPeriodsPerYear = 12;
		NumberOfMonthsInPeriod = 1;
	ElsIf CalendarPeriod = "Quarter" Then
		NumberOfPeriodsPerYear = 4;
		NumberOfMonthsInPeriod = 3;
	EndIf;
	
	For Counter = 1 To NumberOfPeriodsPerYear Do
		AddedElement = ChoiceList.Add(StartOfFillingPeriod, GetPresentationOfRegistrationPeriod(StartOfFillingPeriod, CalendarPeriod));
		If InitialValue = StartOfFillingPeriod Then
			DefaultElement = AddedElement;
		EndIf;
		StartOfFillingPeriod = AddMonth(StartOfFillingPeriod, NumberOfMonthsInPeriod);
	EndDo;
	
	BeginningOfNextYear = EndOfYear(BeginningOfCurYear) + 1;
	ChoiceList.Add(BeginningOfNextYear, (Format(BeginningOfNextYear, NStr("vi = 'ДФ=''гггг''';
																			|ru = 'ДФ=''yyyy''';
																			|en = 'DF=''yyyy'''; fa = 'DF=''yyyy''';
																			|it = 'ДФ=''гггг''';
																			|pl = 'DF=''yyyy''';
																			|tr = 'ДФ=''гггг'''")) + "..."));
	
	AdditionalParameters = AdditionalParametersForSelectingRegistrationPeriod();
	AdditionalParameters.Item = Item;
	AdditionalParameters.StandardProcessing = StandardProcessing;
	AdditionalParameters.RegistrationPeriod = RegistrationPeriod;
	AdditionalParameters.Form             = Form;
	AdditionalParameters.ChoiceNotification1 = ChoiceNotification1;
	AdditionalParameters.InitialValue = InitialValue;
	AdditionalParameters.CalendarPeriod = CalendarPeriod;
	
	Notification = New CallbackDescription("StartSelectingRegistrationPeriodPresentationCompletion", ThisObject, AdditionalParameters);
	Form.ShowChooseFromList(Notification, ChoiceList, Item, DefaultElement);
	
EndProcedure

// Returns additional parameters for selecting a period
// 
// Returns:
// 	Structure - LongDesc:
// 		* CalendarPeriod - String - "Month", "Quarter Of"
// 		* InitialValue  - Date - 
// 		* ChoiceNotification1 - CallbackDescription - 
// 		* Form - ClientApplicationForm - 
// 		* RegistrationPeriod - Date -
// 		* StandardProcessing - Boolean -
// 		* Item - FormField - 
Function AdditionalParametersForSelectingRegistrationPeriod()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item");
	AdditionalParameters.Insert("StandardProcessing");
	AdditionalParameters.Insert("RegistrationPeriod");
	AdditionalParameters.Insert("Form");
	AdditionalParameters.Insert("ChoiceNotification1");
	AdditionalParameters.Insert("InitialValue");
	AdditionalParameters.Insert("CalendarPeriod");
	
	Return AdditionalParameters;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	SelectedElement - ValueListItem - 
// 	AdditionalParameters - See AdditionalParametersForSelectingRegistrationPeriod
Procedure StartSelectingRegistrationPeriodPresentationCompletion(SelectedElement, AdditionalParameters) Export 
	
	If SelectedElement = Undefined Then
		RunCallback(AdditionalParameters.ChoiceNotification1, Undefined);
		Return;
	ElsIf Year(SelectedElement.Value) <> Year(AdditionalParameters.InitialValue) Then
		StartSelectingRegistrationPeriodPresentation(
			AdditionalParameters.Item, 
			AdditionalParameters.StandardProcessing, 
			AdditionalParameters.RegistrationPeriod,
			AdditionalParameters.Form,
			AdditionalParameters.ChoiceNotification1,
			SelectedElement.Value, 
			AdditionalParameters.CalendarPeriod);
		Return;
	EndIf;
	
	RunCallback(AdditionalParameters.ChoiceNotification1, SelectedElement.Value);
	
EndProcedure

#EndRegion

#Region SelectingPeriodFromList

Procedure SelectReportPeriod(Form, Item, PeriodType, BeginOfPeriod, ChoiceHandler)
	
	List = TMCommonUseClientServer.AvailablePeriodValuesByPeriodType(BeginOfPeriod, PeriodType);
	If List.Count() = 0 Then
		Return;
	EndIf;
	
	ListItem = List.FindByValue(BeginOfPeriod);
	
	AdditionalParameters = AdditionalParametersForProcessingPeriodSelection();
	AdditionalParameters.Form = Form;
	AdditionalParameters.Item = Item;
	AdditionalParameters.PeriodType = PeriodType;
	AdditionalParameters.BeginOfPeriod = BeginOfPeriod;
	AdditionalParameters.List = List;
	AdditionalParameters.ChoiceHandler = ChoiceHandler;
	CallbackDescription = New CallbackDescription("SelectReportPeriodCompletion", ThisObject, AdditionalParameters);
	
	Form.ShowChooseFromList(CallbackDescription, List, Item, ListItem);
	
EndProcedure

// Returns:
// 	Structure - LongDesc:
// * ChoiceHandler - CallbackDescription - 
// * List - ValueList - 
// * BeginOfPeriod - Date -
// * PeriodType - EnumRef.AvailableReportPeriods - 
// * Item - FormField - 
// * Form - ClientApplicationForm - 
Function AdditionalParametersForProcessingPeriodSelection()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form");
	AdditionalParameters.Insert("Item");
	AdditionalParameters.Insert("PeriodType");
	AdditionalParameters.Insert("BeginOfPeriod");
	AdditionalParameters.Insert("List");
	AdditionalParameters.Insert("ChoiceHandler");
	
	Return AdditionalParameters;
	
EndFunction

// The service procedure.
//
// Parameters:
// 	SelectedPeriod - ValueListItem - 
// 	AdditionalParameters - See AdditionalParametersForProcessingPeriodSelection
Procedure SelectReportPeriodCompletion(SelectedPeriod, AdditionalParameters) Export

	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	IndexOf = AdditionalParameters.List.IndexOf(SelectedPeriod);
	If IndexOf = 0 Or IndexOf = AdditionalParameters.List.Count() - 1 Then
		SelectReportPeriod(AdditionalParameters.Form, 
							AdditionalParameters.Item, 
							AdditionalParameters.PeriodType, 
							SelectedPeriod.Value, 
							AdditionalParameters.ChoiceHandler);
		Return;
	EndIf;
	
	RunCallback(AdditionalParameters.ChoiceHandler, SelectedPeriod);
	
EndProcedure

// The End procedure for editing the period()
// for more information, see the procedure for editing the period.
Procedure EditPeriodCompletion(Period, AdditionalParameters) Export 

	PeriodParameters_ = AdditionalParameters.PeriodParameters_;
	Object           = AdditionalParameters.Object;
	If Period <> Undefined Then
		If PeriodParameters_.Property("StartDate") Then
			Object[PeriodParameters_.StartDate]= Period.StartDate;
		EndIf; 
		If PeriodParameters_.Property("EndDate") Then
			Object[PeriodParameters_.EndDate]= Period.EndDate;
		EndIf; 
		If PeriodParameters_.Property("Variant") Then
			Object[PeriodParameters_.Variant]= Period.Variant;
		EndIf;
	EndIf;
	
	If AdditionalParameters.Property("NotificationAfterSelection") Then
		RunCallback(AdditionalParameters.NotificationAfterSelection, Period);
	EndIf;
	
EndProcedure

#EndRegion

#Region OtherItems

Procedure RecordObjectIfNecessary(Form, WriteParameters, Cancel = False, ChecksPassed = False) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	Form.ParametersForRecording   = WriteParameters;
	DelayedRecordingIsRequired = WriteParameters.Property("ActionAfterRecording");
	If DelayedRecordingIsRequired Or ChecksPassed Then
		Cancel = True;
		Form.AttachIdleHandler("Attachable_ProcessObjectEntry", 0.1, True);
	Else
		StartMeasuringObjectRecordingTime(Form, WriteParameters);
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ManagedFormExtensionForObjects - the form of the document:
// 		* Object - DocumentObject - 
// 	WriteParameters - Structure - 
// 	Cancel - Boolean - LongDesc
// Returns:
// 	Boolean - LongDesc
Function ProcessObjectEntryInForm(Form, WriteParameters, Cancel = False) Export
	
	ActionAfterRecording = Undefined;
	If WriteParameters.Property("ActionAfterRecording", ActionAfterRecording) Then
		WriteParameters.Delete("ActionAfterRecording");
	EndIf;
	
	Result = False;
	
	If Cancel Then
		Return Result;
	EndIf;
	
	StartMeasuringObjectRecordingTime(Form, WriteParameters);
	Form.NotExecuteCheck1BeforeWrite = True;
	
	Cancel = True;
	WriteParameters.Insert("ForceCloseTheForm", Form.ForceCloseTheForm);
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Form.Object.Ref));
	Result = Form.Write(WriteParameters);
	
	Form.ForceCloseTheForm = False;
	Form.NotExecuteCheck1BeforeWrite = False;
	
	If Result And ActionAfterRecording <> Undefined Then
		RunCallback(ActionAfterRecording, Result);
	EndIf;
	
	Return Result;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document:
// 		* Object - DocumentObject -
// 	Object - DocumentObject - 
// 	WriteParameters  - Structure - 
Procedure PerformActionsAfterRecording(Form, Object, WriteParameters) Export
	
	If Not WriteParameters.Property("NewObject") Then
		Return;
	EndIf;
	
	If WriteParameters.NewObject Then
		TitleText = NStr("vi = 'Tạo:';
						|ru = 'Создание:';
						|en = 'Created:'; fa = 'ایجادشده:';
						|it = 'Creazione:';
						|pl = 'Utworzenie:';
						|tr = 'Oluşturma:'");
	Else
		TitleText = NStr("vi = 'Thay đổi:';
						|ru = 'Изменение:';
						|en = 'Editing:'; fa = 'Editing:';
						|it = 'Modifica:';
						|pl = 'Zmiana:';
						|tr = 'Değişim:'");
	EndIf;
	NotifyUserAboutChangesToObject(Object.Ref, TitleText);
	
	If Form.ForceCloseTheForm Then
		Form.AttachIdleHandler("Attachable_CloseForm", 0.1, True);
	EndIf;
	
EndProcedure

// Notifies you of changes to the document register Used in document logs.
// Used for updating the list.
// 
Procedure NotifyAboutEntryOfDocumentInJournal() Export

	NotifyChanged(Type("InformationRegisterRecordKey.DocumentsRegistry"));
	
EndProcedure

Procedure OnDetermineUpdateAvailability() Export
	
	MinimumAllowedVersion = MinimumAllowedVersion();
	
	ClientParameters = New Structure;
	GeneralPurposeTMServerCall.ClientParametersOnStart(ClientParameters);
	
	If ClientParameters.DataVersion = "0.0.0.0" Then
		Return;
	EndIf;
	
	// Let's check the validity of the update
	If CommonClientServer.CompareVersions(ClientParameters.DataVersion, MinimumAllowedVersion) < 0 Then
		Message =
			NStr("vi = 'Chỉ có thể cập nhật đến phiên bản hiện tại từ phiên bản %1 trở lên.
			|(Thử cập nhật từ phiên bản %2 không hợp lệ)
			|Cần phục hồi cơ sở thông tin từ bản sao dự phòng
			|và cập nhật lại theo tệp 1cv8upd.htm';
			|ru = 'Обновление на текущую версию допустимо только с версии %1 и выше.
			|(Недопустимая попытка обновления с версии %2)
			|Необходимо восстановить информационную базу из резервной копии
			|и повторить обновление согласно файлу 1cv8upd.htm';
			|en = 'Only version %1 and higher can be updated to the current version.
			|(Invalid attempt to update from version %2)
			|Restore the Infobase from backup and try updating again according to file
			|1cv8upd.htm'; fa = 'Only version %1 and higher can be updated to the current version.
			|(Invalid attempt to update from version %2)
			|Restore the Infobase from backup and try updating again according to file
			|1cv8upd.htm';
			|it = 'L''aggiornamento alla versione corrente è consentito solo dalla versione%1 e superiori. 
			|(Tentativo di aggiornamento non valido dalla versione%2)
			| È necessario ripristinare il database  dalla copia
			| di backup e ripetere l''aggiornamento in base al file 1cv8upd.htm';
			|pl = 'Aktualizacja do bieżącej wersji dopuszczalna jest tylko z wersji %1 i wyższej.
			|(Niedopuszczalna próba aktualizacji z wersji %2)
			|Należy przywrócić bazę informacyjną z kopii zapasowej
			|j powtórzyć aktualizację zgodnie z plikiem 1cv8upd.htm';
			|tr = 'Mevcut sürüme güncelleme yalnızca %1 ve üzeri sürümlerden mümkün.
			|(%2 sürümünden güncelleme için geçersiz girişim)
			|Infobase''i bir yedek kopyadan
			|geri yüklemek ve 1cv8upd.htm dosyasına göre güncellemeyi tekrarlamak gerekir'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
			MinimumAllowedVersion,
			ClientParameters.DataVersion);
		Raise Message;
	EndIf;
	
	CheckPossibilityOfUpgradingFromVersion2_5_26(ClientParameters.DataVersion);
	
EndProcedure

// Returns the minimum allowed version to update
// 
// Returns:
// 	String - The minimum allowed version to update
//
Function MinimumAllowedVersion() Export
	
	MinimumAllowedVersion = "11.5.22.49"; // For TM11
	MinimumAllowedVersion = "2.5.22.49"; // for KA2
	MinimumAllowedVersion = "2.5.22.49"; // for UP2
	
	Return MinimumAllowedVersion;
	
EndFunction

// Performs verification of the possibility of updating the c version of ERP, AR 2.5.26 and TM 11.5.26
// The transition from assemblies < 103 must be performed strictly through Assembly 103
// 
Procedure CheckPossibilityOfUpgradingFromVersion2_5_26(DataVersion)
	
	VerificationVersion = "11.5.26";
	VerificationVersion = "2.5.26";
	If CommonClientServer.ConfigurationVersionWithoutBuildNumber(DataVersion) <> VerificationVersion Then
		Return;
	EndIf;
	
	Assembly103 = "11.5.26.103";
	Assembly103 = "2.5.26.103";
	If CommonClientServer.CompareVersions(DataVersion, Assembly103) < 0 Then
		Message =
			NStr("ru = 'Обновление на текущую версию допустимо только с версии %1.
			|(Недопустимая попытка обновления с версии %2)
			|Необходимо восстановить информационную базу из резервной копии
			|и повторить обновление согласно файлу 1cv8upd.htm';
			|vi = 'Only version %1 can be updated to the current version.
			|(Invalid attempt to update from version %2)
			|Restore the Infobase from backup and try updating again according to file
			|1cv8upd.htm';
			|en = 'Only version %1 can be updated to the current version.
			|(Invalid attempt to update from version %2)
			|Restore the Infobase from backup and try updating again according to file
			|1cv8upd.htm'; fa = 'Only version %1 can be updated to the current version.
			|(Invalid attempt to update from version %2)
			|Restore the Infobase from backup and try updating again according to file
			|1cv8upd.htm';
			|it = 'Only version %1 can be updated to the current version.
			|(Invalid attempt to update from version %2)
			|Restore the Infobase from backup and try updating again according to file
			|1cv8upd.htm';
			|pl = 'Only version %1 can be updated to the current version.
			|(Invalid attempt to update from version %2)
			|Restore the Infobase from backup and try updating again according to file
			|1cv8upd.htm';
			|tr = 'Güncel sürüme güncelleme yalnızca %1 sürümünden yapılabilir. 
			| (Sürüm %2''ten geçersiz güncelleme denemesi)
			| Infobase''in yedek kopyadan geri yüklenmesi 
			| ve güncellemenin 1cv8upd.htm dosyasına göre tekrarlanması gereklidir.'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
			Assembly103,
			DataVersion);
		Raise Message;
	EndIf;
		
EndProcedure

// Notifies the user about the execution or cancellation of documents,
// and records information about changes to the object in the history.
//
//	Parameters:
//		List - FormTable - 
//		SelectedRows - Array of DocumentRef - array of document links,
//		ListType - String - type of list documents
//		ListUpdateOptions - Undefined, Structure - update options:
//		* Form - ClientApplicationForm - The Form in which the list of documents is located
//		* ListName - String - the name of the dynamic list Attribute on the Form
//		* UpdateList - Boolean - indicates whether the list needs to be updated
//
Procedure NotificationOfHoldingCancellationOfDocument(List, SelectedRows, ListType, ListUpdateOptions = Undefined)
	
	URL = Undefined;
	If SelectedRows.Count() > 1 Then
		Document = ListType;
		NotificationText1 = NStr("vi = 'Thay đổi (%DocumentsCount%)';
								|ru = 'Изменение (%DocumentsCount%)';
								|en = 'Change (%DocumentsCount%)'; fa = 'Change (%DocumentsCount%)';
								|it = 'Modifica (%DocumentsCount%)';
								|pl = 'Zmiana (%DocumentsCount%)';
								|tr = 'Değişim (%DocumentsCount%)'");
		NotificationText1 = StrReplace(NotificationText1, "%DocumentsCount%", SelectedRows.Count());
	Else
		Document = SelectedRows[0];
		URL = GetURL(Document);
		NotificationText1 = NStr("vi = 'Thay đổi';
								|ru = 'Изменение';
								|en = 'Update'; fa = 'به‌روزرسانی';
								|it = 'Modifica';
								|pl = 'Zmiana';
								|tr = 'Değişim'");
	EndIf;
	
	If ListUpdateOptions <> Undefined Then
		UpdateList = ListUpdateOptions.UpdateList;
	Else
		UpdateList = True;
	EndIf;
	
	If UpdateList Then
		List.Refresh();
	Else
		OperationsWithDocumentJournalsClient.SetFlagForDisplayingIrrelevantDataInList(
					ListUpdateOptions.Form, ListUpdateOptions.ListName);
	EndIf;
	
	ShowUserNotification(NotificationText1, URL, String(Document),
		PictureLib.Information32);
	
EndProcedure

// Completion procedure for pre-selection of Actuality().
// Sets the selection by date of relevance in the list form. Changes the value of the up-to-date date 
// depending on the up-to-date string.
//
// Parameters:
//	DateOfSelection - Date - the date value entered by the user as a result of the dialog.
//	AdditionalParameters - Structure - advanced setting.
//
Procedure WhenSelectingRelevanceSelectionCompletion(DateOfSelection, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	
	If ValueIsFilled(DateOfSelection) Then
		Form[AdditionalParameters.PropsNameEventDate] = DateOfSelection;
		Presentation = NStr("vi = 'Hết hạn vào %Date%';
							|ru = 'Истекает на %Date%';
							|en = 'Expires on %Date%'; fa = 'Expires on %Date%';
							|it = 'Scade il %Date%';
							|pl = 'Wygasa na %Date%';
							|tr = 'Sona eriyor %Date%'");
		Presentation = StrReplace(Presentation, "%Date%", Format(DateOfSelection, "DLF=D"));
		Form[AdditionalParameters.NameOfPropsRelevance] = Presentation;
		Form.Items[AdditionalParameters.ElementNameRelevance].ChoiceList.FindByValue("ExpiresOnDate").Presentation = Presentation;
	EndIf;
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(AdditionalParameters.List,
		Form[AdditionalParameters.NameOfPropsRelevance], Form[AdditionalParameters.PropsNameEventDate], 
		Form.Items[AdditionalParameters.ElementNameRelevance].ChoiceList);
	
	Form.RefreshDataRepresentation();
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	DocumentName - String -
//  List - FormTable - form table 
// Returns:
// 	Array - LongDesc
Function SelectDocumentsByMetadataNameFromSelectedRowsInList(DocumentName, List)
	
	SelectedRows = List.SelectedRows;
	
	SuitableDocuments = New Array();
	
	Type = Type("DocumentRef." + DocumentName);
	
	For Each String In SelectedRows Do
		
		RowData = List.RowData(String);
		
		If TypeOf(RowData["Ref"]) = Type Then
			SuitableDocuments.Add(RowData["Ref"]);
		EndIf;
		
	EndDo;
	
	Return SuitableDocuments;
	
EndFunction

Procedure CreateDocument(BusinessOperation, FillingValues, DocumentName)
				
	FillingValues.Insert("BusinessOperation", BusinessOperation);
	
	ParametersStructure = New Structure("FillingValues", FillingValues);
 	OpenForm("Document." + DocumentName + ".ObjectForm", ParametersStructure);
	
EndProcedure

Procedure ShowQuestionNotSelected(Parameters)
	
	CallbackDescription = New CallbackDescription("ProcessQuestionNotSelected", ThisObject, Parameters);
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chưa chọn lệnh để lập chứng từ.
			|Để tạo chứng từ mà không có lệnh, cần chuyển đến nhật ký ""%1"".';
			|ru = 'Не выбрано распоряжение для оформления документа.
			|Для создания документа без распоряжения необходимо перейти в журнал ""%1"".';
			|en = 'Reference to register the document is not selected.
			|To create the document without reference, go to the ""%1"" log.'; fa = 'Reference to register the document is not selected.
			|To create the document without reference, go to the ""%1"" log.';
			|it = 'Riferimento non selezionato per la formalizzazione del documento.
			| Per la creazione del documento senza riferimenti è necessario passare al registro ""%1"".';
			|pl = 'Nie wybrano zamówienia dla sporządzenia dokumentu.
			|W celu utworzenia dokumentu bez zamówienia należy przejść do dziennika ""%1"".';
			|tr = 'Belge düzenleme için sipariş seçilmedi.
			|Düzenleme olmadan bir belge oluşturmak için ""%1"" günlüğüne gidilmeli.'"),
		Parameters.JournalSynonym);
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Chuyển đến biểu ghi';
											|ru = 'Перейти в журнал';
											|en = 'Go to log'; fa = 'Go to log';
											|it = 'Passare al registro';
											|pl = 'Przejdź do dziennika';
											|tr = 'Deftere git'"));
	Buttons.Add(DialogReturnCode.Cancel);
	
	ShowQueryBox(
		CallbackDescription,
		QueryText,Buttons,
		,
		DialogReturnCode.Cancel,
		NStr("vi = 'Không có đơn nào được chọn';
			|ru = 'Не выбрано распоряжение';
			|en = 'Reference is not selected'; fa = 'Reference is not selected';
			|it = 'Riferimento non selezionato';
			|pl = 'Nie wybrano zamówienia';
			|tr = 'Sipariş seçilmedi'"));
	
EndProcedure

Procedure ProcessQuestionNotSelected(Result, Parameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		OpenLog(Parameters);
		
	EndIf;
	
EndProcedure

Function FieldInsideTable(Form, Item)
	
	If TypeOf(Item.Parent) = Type("FormTable") Then
		Return Item.Parent;
	ElsIf TypeOf(Item.Parent) = Type("ClientApplicationForm") Then
		Return Undefined;
	Else	
		Return FieldInsideTable(Form, Item.Parent);
	EndIf;
	
EndFunction

// The service method.
//
// Parameters:
// 	Result - Arbitrary 
// 	AdditionalParameters - See AdditionalParametersForProcessingFormOpeningAfterCheckingDocumentCompletion.
//
Procedure OpenFormAfterCheckingPostingDocumentCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(AdditionalParameters.ParameterNameLink) Then
		
		DocumentRef = AdditionalParameters.OwnerForm.Object.Ref;
		
		BusinessOperation = AdditionalParameters.FormParameters.BusinessOperation;
		If ValueIsFilled(BusinessOperation) Then
			
			Basis = New Structure;
			Basis.Insert("DocumentBasis", DocumentRef);
			Basis.Insert("BusinessOperation", BusinessOperation);
			
		Else
			Basis = DocumentRef;
		EndIf;
		
		AdditionalParameters.FormParameters.Insert(AdditionalParameters.ParameterNameLink, Basis);
		
	EndIf;
	
	OpenForm(AdditionalParameters.FormName,
		AdditionalParameters.FormParameters,
		AdditionalParameters.OwnerForm,,,,,
		AdditionalParameters.FormWindowOpeningMode);
	
EndProcedure

Procedure ProcessNotificationAfterCheckingWhetherDocumentWasCompletedCompletion(QuestionResult, AdditionalParameters) Export

	DocumentPosted = False;
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		Try
			Form = AdditionalParameters.Form; // ManagedFormExtensionForObjects
			WriteParameters = New Structure;
			WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
			If CommonClientServer.HasAttributeOrObjectProperty(Form, "NotExecuteCheck1BeforeWrite") Then
				// If there is this requisite, then the mechanics of recording through notification processing
				// is involved, i.e. this procedure will not record the object, and the processing of the notification will be performed by the function to process the recording of the object in the form
				WriteParameters.Insert("ActionAfterRecording", AdditionalParameters.Notification);
			EndIf;
			DocumentPosted = Form.Write(WriteParameters);
		Except
			ShowMessageBox(,NStr("vi = 'Không thể thực hiện kết chuyển chứng từ';
								|ru = 'Не удалось выполнить проведение документа';
								|en = 'Failed to post document'; fa = 'Failed to post document';
								|it = 'Non è stato possibile eseguire la registrazione del documento';
								|pl = 'Nie udało się wykonać zatwierdzenie dokumentu';
								|tr = 'Belge kaydedilemedi'"));
		EndTry;
	EndIf;
	
	If DocumentPosted Then
		RunCallback(AdditionalParameters.Notification, DocumentPosted);
	EndIf;
	
EndProcedure

// Function-constructor of parameters for the method of determining the cost price, 
// which are passed between the forms of the document "Return of goods from the customer".
// 
// Returns:
// 	Structure - goods row data:
// 		* RowsOfProductsTable - Undefined
//
Function NewProductStructure() Export
	
	Result = New Structure();
	Result.Insert("RowsOfProductsTable");
	Return Result;
	
EndFunction

// Function-constructor of parameters for the method of determining the cost price, 
// which are passed between the forms of the document "Return of goods from the customer".
// 
// Returns:
// 	Structure - composition of fields:
// * TDCost                       - Number
// * CDCost                       - Number
// * CostLocal                     - Number
// * CostExcludingVAT_                   - Number
// * Cost_                         - Number 
// * DateOfCostFillingByPriceType - Date 
// * CostPriceKind                  - CatalogRef.TypesOfPrices 
// * Id                         - Number
// * DocumentSalesOfGoodsAndServices                    - DocumentRef.CustomerInvoice, DocumentRef.RetailSalesReport -
// * CostDefiningMethod        - EnumRef.WaysToCalculateReturnCost
//  
Function NewElementArrayProducts() Export
	
	Result = New Structure();
	
	Result.Insert("CostDefiningMethod");
	Result.Insert("DocumentSalesOfGoodsAndServices");
	Result.Insert("Id");
	
	Result.Insert("CostPriceKind");
	Result.Insert("DateOfCostFillingByPriceType");
	Result.Insert("Cost_");
	Result.Insert("CostExcludingVAT_");
	
	Result.Insert("CostLocal");
	Result.Insert("CDCost");
	Result.Insert("TDCost");
	
	Return Result;
	
EndFunction

// Returns:
//
// 	Structure:
// 		* FormName - String
// 		* ParameterNameLink - String
// 		* OwnerForm - ClientApplicationForm:
// 			** Object - DocumentObject
// 		* FormParameters - Structure:
// 			** BusinessOperation - EnumRef.BusinessTransactions
//
Function AdditionalParametersForProcessingFormOpeningAfterCheckingDocumentCompletion()
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("FormName", "");
	AdditionalParameters.Insert("ParameterNameLink", "");
	AdditionalParameters.Insert("OwnerForm");
	
	AdditionalParameters.Insert("FormParameters", New Structure());
	AdditionalParameters.FormParameters.Insert("BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.EmptyRef"));
	
	Return AdditionalParameters;
	
EndFunction

#EndRegion

#EndRegion
