#Region Variables

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Return of the form for analysis
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	ItemsAndDimensionsSelectionParameters = Documents.ApplicationForBusinessTrip.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	CalculateNumberOfDays();
	//Update the status of the call to the Smartway();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.ApplicationForBusinessTrip.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_BankAccountIssue"
		Or EventName = "Write_CashVoucher" Then
		FillInPaymentDetailsForApplication();
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Object.StartDate < Object.Date Then
		Common.MessageToUser(
					NStr("vi = 'Ngày đầu chuyến đi không được nhỏ hơn ngày của giấy đề nghị.';
						|ru = 'Дата начала поездки не может быть меньше даты заявки.';
						|en = 'Business trip start date must be later than the application date.'; fa = 'Business trip start date must be later than the application date.';
						|it = 'Дата начала поездки не может быть меньше даты заявки.';
						|pl = 'Business trip start date must be later than the application date.';
						|tr = 'Seyahatin başlangıç tarihi başvuru tarihinden önce olamaz.'")
					,
					,"StartDate"
					,"Object.StartDate"
					,Cancel);

	EndIf;
	
	If Object.FundsIssueToAdvanceHolder.Total("Sum") <> 0 Then
		
		If ValueIsFilled(Object.RequiredPaymentDate) And Object.RequiredPaymentDate < Object.Date Then
			Common.MessageToUser(
						NStr("vi = 'Ngày thanh toán không được nhỏ hơn ngày của giấy đề nghị.';
							|ru = 'Дата платежа не может быть меньше даты заявки.';
							|en = 'Payment date must be later than the application date.'; fa = 'Payment date must be later than the application date.';
							|it = 'Дата платежа не может быть меньше даты заявки.';
							|pl = 'Payment date must be later than the application date.';
							|tr = 'Ödeme tarihi başvuru tarihinden önce olamaz.'")
						,
						,"RequiredPaymentDate"
						,"Object.RequiredPaymentDate"
						,Cancel);
		EndIf;
		
		If Not ValueIsFilled(Object.RequiredPaymentDate) Then
			Common.MessageToUser(
						NStr("vi = 'Chưa điền ngày thanh toán.';
							|ru = 'Дата платежа не заполнена.';
							|en = 'Payment date is not filled.'; fa = 'Payment date is not filled.';
							|it = 'Дата платежа не заполнена.';
							|pl = 'Payment date is not filled.';
							|tr = 'Ödeme tarihi doldurulmadı.'")
						,
						,"RequiredPaymentDate"
						,"Object.RequiredPaymentDate"
						,Cancel);
					EndIf;
					
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	DisplayBookingInformation();
	FillInPaymentDetailsForApplication();
	
	ConfigureDependentFormElementsOnServer();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// Used for automatic updating of the payment calendar form
	Notify("Write_PaymentRequest", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Parameters:
//     Item - FormField - Changed Bank details
//
&AtClient
Procedure FormDetailsWhenChanging(Item)
	
	If ElementInGroup(Item, "GroupOrderThere") Then
		
		SetHintWhenOrderingTickets(ThisObject, False);
		If ElementInGroup(Item, "GroupTicketsToDestination") Then
			FillInBookingParameters(ThisObject, Items.GroupOrderThere, False);
		EndIf;
		
	ElsIf ElementInGroup(Item, "GroupOrderReturnTickets") Then
		
		SetHintWhenOrderingTickets(ThisObject, True);
		If ElementInGroup(Item, "GroupReturnTickets") Then
			FillInBookingParameters(ThisObject, Items.GroupOrderReturnTickets, True);
		EndIf;
		
	EndIf;
	
	SetAccommodationHint(ThisObject);
	ChangeParameterOfBookingElement(ThisObject, "BookAccommodation_", False);
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If CurrentStatus <> Object.Status Then
		StatusOnChangeServer();
		CurrentStatus = Object.Status;
	EndIf;
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	If Object.Status = Enums.EmployeeApplicationStatuses.AgreedUpon Then
		Object.WhoDecided = Users.CurrentUser();
	EndIf;
	
	SetListOfStatuses();
	ConfigureDependentFormElementsOnServer("Status");
	
EndProcedure

&AtClient
Procedure EmployeeOnChange(Item)
	
	FillContactInformation();
	
EndProcedure

&AtClient
Procedure PersonsListOnChange(Item)
	
	If Object.PersonsList Then
		
		If Not Object.TravellingEmployees.Count() Then
			TSRow = Object.TravellingEmployees.Add();
			TSRow.Employee = Object.Employee;
		EndIf;
		
		Object.Employee = Undefined;
		Object.PersonalAccount = Undefined;
	Else
		For Each TSRow In Object.FundsIssueToAdvanceHolder Do
			TSRow.Employee = Undefined;
			TSRow.PersonalAccount = Undefined;
		EndDo;
	EndIf;
	
	ListOfPersonsChangedOnServer();
	
EndProcedure

&AtServer
Procedure ListOfPersonsChangedOnServer()
	
	Items.GroupSecondedEmployees.Title = HeadingSecondedEmployees();
	
	ConfigureDependentFormElementsOnServer("PersonsList");
	
EndProcedure

&AtClient
Procedure StartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.StartDate > Object.EndDate Then
		Object.EndDate = Object.StartDate;
	EndIf;
	
	PeriodOnChange();
	
EndProcedure

&AtClient
Procedure EndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.EndDate < Object.StartDate Then
		Object.StartDate = Object.EndDate;
	EndIf;
	
	PeriodOnChange();
	
EndProcedure

&AtClient
Procedure PeriodOnChange()
	
	Object.BookDepartureToDestinationNotEarlier = Object.StartDate;
	Object.BookArrivalToDestinationNotLater = Object.StartDate;
	Object.BookReturnDepartureNotEarlier = Object.EndDate;
	Object.BookArrivalBackNotLater = Object.EndDate;
	
	CalculateNumberOfDays();
	
EndProcedure

&AtClient
Procedure NumberOfDaysOnChange(Item)
	
	SecondsPerMinute = 60;
	MinutesPerHour = 60;
	HoursPerDay = 24;
	
	Object.EndDate = Object.StartDate + (NumberOfDays - 1) * SecondsPerMinute * MinutesPerHour * HoursPerDay;
	
	Items.NumberOfDays.Title = TMCommonUseClientServer.DeclensionOfWord(
		NumberOfDays, NStr("vi = 'ngày';
							|ru = 'день, дня, дней, м';
							|en = 'day, days, days'; fa = 'day, days, days';
							|it = 'день, дня, дней, м';
							|pl = 'dzień, dnia, dni, m';
							|tr = 'gün, gün, günler'"));
	
EndProcedure

&AtClient
Procedure OverLimitsOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure LabelActualPaymentClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", "FulfillmentOfPaymentRequests");
	FormParameters.Insert("PurposeUseKey", "FulfillmentOfPaymentRequests");
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	Filter = New Structure;
	Filter.Insert("PaymentRequest", Object.Ref);
	FormParameters.Insert("Filter", Filter);
	
	OpenForm("Report.FulfillmentOfPaymentRequests.Form", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure BookAirlineToDestinationOnChange(Item)
	
	SetHintWhenOrderingTickets(ThisObject, False);
	FillInBookingParameters(ThisObject, Items.GroupOrderThere, False);
	
EndProcedure

&AtClient
Procedure BookTrainToDestinationOnChange(Item)
	
	SetHintWhenOrderingTickets(ThisObject, False);
	FillInBookingParameters(ThisObject, Items.GroupOrderThere, False)
	
EndProcedure

&AtClient
Procedure BookAirlineBackOnChange(Item)
	
	SetHintWhenOrderingTickets(ThisObject, True);
	FillInBookingParameters(ThisObject, Items.GroupOrderReturnTickets, True);
	
EndProcedure

&AtClient
Procedure BookTrainBackOnChange(Item)
	
	SetHintWhenOrderingTickets(ThisObject, True);
	FillInBookingParameters(ThisObject, Items.GroupOrderReturnTickets, True);
	
EndProcedure

&AtClient
Procedure BookDepartureToDestinationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProcessingSelectionOfBookingObjects(Item.Name, ValueSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BookDepartureToDestinationAutoComplete(
			Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure BookDepartureToDestinationTextEditEnd(
			Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	EndOfEnteringTextOfBookingElements(Text, ChoiceData, StandardProcessing);

EndProcedure

&AtClient
Procedure BookArrivalToDestinationChoiceProcessing(Item, ValueSelected, StandardProcessing)

	ProcessingSelectionOfBookingObjects(Item.Name, ValueSelected, StandardProcessing);

EndProcedure

&AtClient
Procedure BookArrivalToDestinationAutoComplete(
			Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure BookArrivalToDestinationTextEditEnd(
			Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	EndOfEnteringTextOfBookingElements(Text, ChoiceData, StandardProcessing);

EndProcedure

&AtClient
Procedure BookDestinationTransferLocationChoiceProcessing(Item, ValueSelected, StandardProcessing)

	ProcessingSelectionOfBookingObjects(Item.Name, ValueSelected, StandardProcessing);
	
	Object.BookDestinationTransferLocationItIsRegion = ValueSelected.ThisIsTheRegion;

EndProcedure

&AtClient
Procedure BookDestinationTransferLocationAutoComplete(
			Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure BookDestinationTransferLocationTextEditEnd(
			Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	EndOfEnteringTextOfBookingElements(Text, ChoiceData, StandardProcessing);

EndProcedure

&AtClient
Procedure BookReturnDepartureChoiceProcessing(Item, ValueSelected, StandardProcessing)

	ProcessingSelectionOfBookingObjects(Item.Name, ValueSelected, StandardProcessing);

EndProcedure

&AtClient
Procedure BookReturnDepartureAutoComplete(
			Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure BookReturnDepartureTextEditEnd(
			Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	EndOfEnteringTextOfBookingElements(Text, ChoiceData, StandardProcessing);

EndProcedure

&AtClient
Procedure BookArrivalBackChoiceProcessing(Item, ValueSelected, StandardProcessing)

	ProcessingSelectionOfBookingObjects(Item.Name, ValueSelected, StandardProcessing);

EndProcedure

&AtClient
Procedure BookArrivalBackAutoComplete(
			Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	Return;

EndProcedure

&AtClient
Procedure BookArrivalBackTextEditEnd(
			Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	EndOfEnteringTextOfBookingElements(Text, ChoiceData, StandardProcessing);

EndProcedure

&AtClient
Procedure BookReturnTransferLocationChoiceProcessing(Item, ValueSelected, StandardProcessing)

	ProcessingSelectionOfBookingObjects(Item.Name, ValueSelected, StandardProcessing);
	
	Object.BookReturnTransferLocationItIsRegion = ValueSelected.ThisIsTheRegion;

EndProcedure

&AtClient
Procedure BookReturnTransferLocationAutoComplete(
			Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	Return;

EndProcedure

&AtClient
Procedure BookReturnTransferLocationTextEditEnd(
			Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	EndOfEnteringTextOfBookingElements(Text, ChoiceData, StandardProcessing);

EndProcedure

&AtClient
Procedure BookAccommodation_ChoiceProcessing(Item, ValueSelected, StandardProcessing)

	ProcessingSelectionOfBookingObjects(Item.Name, ValueSelected, StandardProcessing);
	
	Object.BookAccommodationsItIsRegion = ValueSelected.ThisIsTheRegion;

EndProcedure

&AtClient
Procedure BookAccommodation_AutoComplete(
			Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure BookAccommodation_TextEditEnd(
			Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	EndOfEnteringTextOfBookingElements(Text, ChoiceData, StandardProcessing);

EndProcedure

&AtClient
Procedure BookingDetailsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If Not (StrStartsWith(FormattedStringURL, "e1c:")
		Or StrStartsWith(FormattedStringURL, "e1cib/")
		Or StrStartsWith(FormattedStringURL, "e1ccs/")) Then
		
		StandardProcessing = False;
		ReservationsLink = ReservationsLink(FormattedStringURL);
		
		FormParameters = New Structure;
		FormParameters.Insert("FileOwner",  ReservationsLink);
		FormParameters.Insert("ReadOnly", ReadOnly);
		
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Function ReservationsLink(BookingID)
	
	Return Documents.ElectronicTicketTransaction.GetRef(New UUID(BookingID));
	
EndFunction

&AtClient
Procedure TheStatusOfTheReservationProcessingOfTheNavigationLinks(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure

#EndRegion

#Region EventHandlersForTablePartEmployees

&AtClient
Procedure TravellingEmployeesOnChange(Item)
	
	Items.GroupSecondedEmployees.Title = HeadingSecondedEmployees();
	
EndProcedure

&AtClient
Procedure PaymentMethodOnChange(Item)
	
	If PaymentMethod = "NonCash" Then
		Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.BankAccountPayment");
	ElsIf PaymentMethod = "Cash" Then
		Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.CashAccountPayment_");
	Else
		PaymentMethod = "InAnyForm";
		Object.PaymentMethodOfPaymentRequest = PredefinedValue("Enum.PaymentForms.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("PaymentMethodOfPaymentRequest");
	
EndProcedure

&AtClient
Procedure EmployeesHROnChange(Item)
	
	Items.GroupToIssueAReport.Title = NStr("vi = 'Chi tiền tạm ứng để đi công tác:';
											|ru = 'Выдать под отчет на командировочные расходы:';
											|en = 'Issue travel expenses to advance holder:'; fa = 'Issue travel expenses to advance holder:';
											|it = 'Emettere fondi di viaggio dietro una nota spese:';
											|pl = 'Wydaj zaliczkę na koszty podróży służbowej:';
											|tr = 'Seyahat giderleri için raporla:'") +
		" " + Object.FundsIssueToAdvanceHolder.Total("Sum") + " " + String(Object.Currency);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExpenses

&AtClient
Procedure ExpensesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.Expenses");
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpensesExpenseCommentStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject,
		"Items.Expenses.CurrentData.ExpenseComment", NStr("vi = 'Chi tiết hóa chi phí';
															|ru = 'Детализация расходов';
															|en = 'Expense details'; fa = 'جزئیات هزینه';
															|it = 'Dettaglio delle spese';
															|pl = 'Detalizacja rozchodów';
															|tr = 'Giderlerin ayrıştırılması'"));
	
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

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
//End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SelectPeriod(Command)
	
	Notification = New CallbackDescription("SelectPeriodCompletion", ThisObject);
		
	TMCommonUseClient.EditPeriod(
		Object,
		New Structure("StartDate, EndDate", "StartDate", "EndDate"),
		Notification);
	
EndProcedure

&AtClient
Procedure SelectPeriodCompletion(Period, AdditionalParameters) Export
	
	If Period <> Undefined Then
		CalculateNumberOfDays();
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateNumberOfDays()
	
	SecondsPerMinute = 60;
	MinutesPerHour = 60;
	HoursPerDay = 24;
	
	NumberOfDays = (Object.EndDate - Object.StartDate) / (SecondsPerMinute * MinutesPerHour * HoursPerDay) + 1;
	
	Items.NumberOfDays.Title = TMCommonUseClientServer.DeclensionOfWord(
		NumberOfDays, NStr("vi = 'ngày';
							|ru = 'день, дня, дней, м';
							|en = 'day, days, days'; fa = 'day, days, days';
							|it = 'день, дня, дней, м';
							|pl = 'dzień, dnia, dni, m';
							|tr = 'gün, gün, günler'"));
	
EndProcedure

&AtClient
Procedure FillInEmployees(Command)
	
	FillEmployeesOnServer();
	
EndProcedure

&AtServer
Procedure FillEmployeesOnServer()
	
	ArrayOfEmployees = Object.TravellingEmployees.Unload().UnloadColumn("Employee");
	ArrayOfEmployees = TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfEmployees);
	
	Object.FundsIssueToAdvanceHolder.Clear();
	For Each EmployeeLink In ArrayOfEmployees Do
		Object.FundsIssueToAdvanceHolder.Add().Employee = EmployeeLink;
	EndDo;
	
EndProcedure

&AtClient
Procedure DownloadAll(Command)
	
	FileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	FileDialog.Show(New CallbackDescription("DownloadAllCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure DownloadAllCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	NumberOfFiles = DownloadEverythingOnServer(Result[0]);
	
	If NumberOfFiles Then
		ShowUserNotification(StrTemplate(NStr("vi = 'Tệp đã tải xuống (%1)';
												|ru = 'Файлы скачаны (%1)';
												|en = 'Files downloaded (%1)'; fa = 'Files downloaded (%1)';
												|it = 'File scaricati (%1)';
												|pl = 'Pobrano pliki (%1)';
												|tr = 'Dosyalar indirildi (%1)'"), NumberOfFiles));
	Else
		ShowUserNotification(NStr("vi = 'Không có tệp để tải về';
									|ru = 'Нет файлов для скачивания';
									|en = 'No files for download'; fa = 'No files for download';
									|it = 'Non ci sono file da scaricare';
									|pl = 'Brak plików do pobierania';
									|tr = 'İndirim için dosyalar mevcut değil'"));
	EndIf;
	
EndProcedure

&AtServer
Function DownloadEverythingOnServer(Directory)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CatalogData.Ref AS Ref,
	|	CatalogData.Description AS Description,
	|	CatalogData.Extension AS Extension
	|FROM
	|	Catalog.ElectronicTicketTransactionAttachedFiles AS CatalogData
	|WHERE
	|	CatalogData.FileOwner IN (&ListOfTickets)
	|	AND NOT CatalogData.DeletionMark
	|";
	
	Query.SetParameter("ListOfTickets", ListOfTickets);
	
	NumberOfFiles = 0;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FileData = FilesOperations.FileBinaryData(Selection.Ref, False); // BinaryData
		If FileData <> Undefined Then
			FileData.Write(Directory + "\" + Selection.Description + "." + Selection.Extension);
			NumberOfFiles = NumberOfFiles + 1;
		EndIf;
	EndDo;
	
	Return NumberOfFiles;
	
EndFunction

&AtClient
Procedure UpdateBookingDetails(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure CloseRequest(Command)
	
	Object.Closed_ = True;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	
	Write(WriteParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region Properties

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ApprovalRight = UserRightsCached.ApproveApplicationsForBusinessTrip();
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	InitializeBookingElements();
	FillInBookingParameters(ThisObject, Items.GroupOrderThere, False);
	FillInBookingParameters(ThisObject, Items.GroupOrderReturnTickets, True);
	FillInBookingParameters(ThisObject, Items.GroupAccommodation);
	
	DisplayBookingInformation();
	FillInPaymentDetailsForApplication();
	SetListOfStatuses();
	FormItemsManagement();
	
	ConfigureDependentFormElementsOnServer();
	If LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
		Items.OverLimits.Title = NStr("vi = 'Không có kiểm soát hạn mức';
										|ru = 'Без контроля лимита';
										|en = 'Without limit control'; fa = 'Without limit control';
										|it = 'Без контроля лимита';
										|pl = 'Without limit control';
										|tr = 'Limit kontrolü olmadan'");
	EndIf;
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("ApprovalRight");
	FormAttributes.Insert("UseSmartwayIntegration");
	FormAttributes.Insert("BalanceOfPayment");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure FillInPaymentDetailsForApplication()
	
	If Not ValueIsFilled(Object.Ref) Then
		BalanceOfPayment = -1;
	Else
		BalanceOfPayment = BalanceOfPaymentForApplication(Object.Ref);
	EndIf;
	
	If BalanceOfPayment < 0 Then
		LabelActualPayment = StringFunctions.FormattedString(
			NStr("vi = '<span style=""color: %1"">Chưa thanh toán</span>';
				|ru = '<span style=""color: %1"">Не оплачена</span>';
				|en = '<span style=""color: %1"">Not paid</span>'; fa = '<span style=""color: %1"">Not paid</span>';
				|it = '<span style=""color: %1"">Не оплачена</span>';
				|pl = '<span style=""color: %1"">Not paid</span>';
				|tr = '<span style=""color: %1"">Ödeme yapılmadı</span>'"), "TextColorWarning");
	ElsIf BalanceOfPayment = 0 Then
		If Object.Closed_ Then
			AmountClosed = AmountClosed(Object.Ref);
			LabelActualPayment = StringFunctions.FormattedString(
				NStr("vi = 'Đã thanh toán một phần, <span style=""color: %1"">đã đóng: %2</span>';
					|ru = 'Оплачена частично, <span style=""color: %1"">закрыто: %2</span>';
					|en = 'Paid partially, <span style=""color: %1"">closed: %2</span>'; fa = 'Paid partially, <span style=""color: %1"">closed: %2</span>';
					|it = 'Оплачена частично, <span style=""color: %1"">закрыто: %2</span>';
					|pl = 'Paid partially, <span style=""color: %1"">closed: %2</span>';
					|tr = 'Kısmen ödenmiş, <span style=""color: %1"">kapalı: %2</span>'"),
				"TextColorWarning", PrintFormGeneration.SumFormat(AmountClosed, Object.Currency));
		Else
			LabelActualPayment = StringFunctions.FormattedString(NStr("vi = 'Trả đầy đủ';
																		|ru = 'Оплачена полностью';
																		|en = 'Fully paid'; fa = 'Fully paid';
																		|it = 'Pagata interamente';
																		|pl = 'Opłacono w całości';
																		|tr = 'Tamamen ödenmiş'"));
		EndIf;
	Else
		LabelActualPayment = StringFunctions.FormattedString(
			NStr("vi = 'Đã thanh toán một phần, <span style=""color: %1"">chưa thanh toán: %2</span>';
				|ru = 'Оплачена частично, <span style=""color: %1"">не оплачено: %2</span>';
				|en = 'Paid partially, <span style=""color: %1"">not paid: %2</span>'; fa = 'Paid partially, <span style=""color: %1"">not paid: %2</span>';
				|it = 'Оплачена частично, <span style=""color: %1"">не оплачено: %2</span>';
				|pl = 'Paid partially, <span style=""color: %1"">not paid: %2</span>';
				|tr = 'Kısmen ödenmiş, <span style=""color: %1"">ödeme yapılmadı: %2</span>'"),
			"TextColorWarning", PrintFormGeneration.SumFormat(BalanceOfPayment, Object.Currency));
	EndIf;
	
	ConfigureDependentFormElementsOnServer("BalanceOfPayment");
	
EndProcedure

&AtServerNoContext
Function BalanceOfPaymentForApplication(Ref)
	
	Result = Undefined;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	1
	|FROM
	|	AccumulationRegister.CashToBePaid AS Cash
	|WHERE
	|	Cash.PaymentRequest = &Ref
	|	AND Cash.RecordType = VALUE(AccumulationRecordType.Expense)
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Cash.SumBalance AS NotPaid
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(,
	|		PaymentRequest = &Ref
	|	) AS Cash
	|";
	
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	If ResultsArray[0].IsEmpty() Then
		Result = -1;
	Else
		Result = ResultsArray[1].Unload()[0].NotPaid;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function AmountClosed(Ref)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	-SUM(Cash.Sum) AS Closed
	|FROM
	|	AccumulationRegister.CashToBePaid AS Cash
	|WHERE
	|	Cash.PaymentRequest = &Ref
	|	AND Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND Cash.Sum < 0
	|";
	
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return QueryResult.Unload()[0].Closed;
	
EndFunction

&AtServer
Procedure DisplayBookingInformation()
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	Query = New Query;
	ArrayOfTexts = New Array;
	
	QueryText =
	"SELECT
	|	DocumentData.TicketNumber                             AS Number,
	|	DocumentData.PostingDate                         AS StrtDate,
	|	DocumentData.ArrivalDate                            AS FinishDate,
	|	DocumentData.DocumentAmount                          AS Sum,
	|	PRESENTATION(DocumentData.Currency)                   AS Currency,
	|	PRESENTATION(DocumentData.ServiceType)                AS ServiceType,
	|	CAST(DocumentData.TripDetails AS STRING(100)) AS Details_3,
	|	DocumentData.Ref                                  AS Ref,
	|	COUNT(Files.Ref)                                AS FilesCount
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|	LEFT JOIN
	|		Catalog.ElectronicTicketTransactionAttachedFiles AS Files
	|	ON
	|		Files.FileOwner = DocumentData.Ref
	|WHERE
	|	DocumentData.DocumentBasis = &Ref
	|	AND NOT DocumentData.DeletionMark
	|GROUP BY
	|	DocumentData.Ref";
	
	ArrayOfTexts.Add(QueryText);
	
	
	Query.Text = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	Query.SetParameter("Ref", Object.Ref);
	
	BookingLine = "";
	TemplateRef1 = NStr("vi = '%1 %2';
						|ru = '%1 %2';
						|en = '%1 %2'; fa = '%1 %2';
						|it = '%1 %2';
						|pl = '%1 %2';
						|tr = '%1 %2'");
	TicketTemplate = NStr("vi = '%1 - %2, %3 %4';
							|ru = '%1 - %2, %3 %4';
							|en = '%1 - %2, %3 %4'; fa = '%1 - %2, %3 %4';
							|it = '%1 - %2, %3 %4';
							|pl = '%1 - %2, %3 %4';
							|tr = '%1 - %2, %3 %4'");
	TemplateFiles = NStr("vi = 'Tệp (%1)';
						|ru = 'Файлы (%1)';
						|en = 'Files (%1)'; fa = 'Files (%1)';
						|it = 'File (%1)';
						|pl = 'Pliki (%1)';
						|tr = 'Dosyalar (%1)'");
	
	ListOfTickets.Clear();
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	While Selection.Next() Do
		
		ListOfTickets.Add(Selection.Ref);
		
		BookingLine = BookingLine
			+ "<a href = " + GetURL(Selection.Ref) + ">" + StrTemplate(TemplateRef1, Selection.ServiceType, Selection.Number) + "</a>"
			+ " " + StrTemplate(TicketTemplate, Selection.StrtDate, Selection.FinishDate, Selection.Sum, Selection.Currency)
			+ ?(Selection.FilesCount > 0, "   " + "<a href = " + String(Selection.Ref.UUID()) + ">" + StrTemplate(TemplateFiles, Selection.FilesCount) + "</a>", "")
			+ Chars.LF;
	EndDo;
	
	BookingDetails = StringFunctions.FormattedString(BookingLine);
	
	Items.DownloadAll.Visible = ListOfTickets.Count();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetHintWhenOrderingTickets(Form, ReverseDirection)
	
	Properties = BookingProperties(Form, ReverseDirection);
	
	If Properties.Book Then
		
		Hints = New Array;
		Hints.Add(NStr("vi = 'Tỉnh/thành phố';
						|ru = 'Регион';
						|en = 'Region'; fa = 'منطقه';
						|it = 'Regione';
						|pl = 'Region';
						|tr = 'Bölge'"));
		
		If Properties.BookPlane Then
			Hints.Add(NStr("vi = 'mã sân bay';
							|ru = 'код аэропорта';
							|en = 'airport code'; fa = 'airport code';
							|it = 'codice aeroporto';
							|pl = 'kod lotniska';
							|tr = 'hava limanı kodu'"));
		EndIf;
		
		If Properties.BookTrain Then
			Hints.Add(NStr("vi = 'trạm tàu hỏa';
							|ru = 'ж/д станция';
							|en = 'railroad station'; fa = 'railroad station';
							|it = 'stazione ferroviaria';
							|pl = 'stacja kolejowa';
							|tr = 'demir yolu istasyonu'"));
		EndIf;
		
		ToolTip = StrConcat(Hints, ", ");
	
		Properties.ElementOfDeparture.InputHint = ToolTip;
		Properties.ElementArrival.InputHint = ToolTip;
		
		If Properties.BookTransfer Then
			
			ToolTip = StrTemplate(NStr("vi = '%1 hoặc khách sạn';
										|ru = '%1 или отель';
										|en = '%1 or hotel'; fa = '%1 or hotel';
										|it = '%1 oppure albergo';
										|pl = '%1 lub hotel';
										|tr = '%1 veya otel'"), ToolTip);
			Properties.TransferItem.InputHint = ToolTip;
			
		Else
			Properties.TransferItem.InputHint = "";
		EndIf;
		
	Else
		Properties.ElementOfDeparture.InputHint = "";
		Properties.ElementArrival.InputHint = "";
		Properties.TransferItem.InputHint = "";
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAccommodationHint(Form)
	
	If Form.Object.BookAccommodation Then
		Form.Items.BookAccommodation_.InputHint = NStr("vi = 'Khách sạn (tỉnh, thành phố hoặc tên)';
														|ru = 'Отель (регион или название)';
														|en = 'Hotel (region or name)'; fa = 'Hotel (region or name)';
														|it = 'Albergo (regione o nome)';
														|pl = 'Hotel (region lub nazwa)';
														|tr = 'Otel (bölge veya adı)'");
	Else
		Form.Items.BookAccommodation_.InputHint = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetListOfStatuses()
	
	ChoiceList = Items.Status.ChoiceList;
	
	If Not ApprovalRight Then
		
		ChoiceList.Clear();
		ChoiceList.Add(Enums.EmployeeApplicationStatuses.IsPrepared);
		ChoiceList.Add(Enums.EmployeeApplicationStatuses.IsRejected);
		
		If ApprovalRight Or Object.Status = Enums.EmployeeApplicationStatuses.AgreedUpon Then
			ChoiceList.Add(Enums.EmployeeApplicationStatuses.AgreedUpon);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Items.GroupSecondedEmployees.Title = HeadingSecondedEmployees();
	
	Items.GroupToIssueAReport.Title = NStr("vi = 'Chi tiền tạm ứng để đi công tác:';
											|ru = 'Выдать под отчет на командировочные расходы:';
											|en = 'Issue travel expenses to advance holder:'; fa = 'Issue travel expenses to advance holder:';
											|it = 'Emettere fondi di viaggio dietro una nota spese:';
											|pl = 'Wydaj zaliczkę na koszty podróży służbowej:';
											|tr = 'Seyahat giderleri için raporla:'") +
		" " + Object.FundsIssueToAdvanceHolder.Total("Sum") + " " + String(Object.Currency);
		
	If Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.BankAccountPayment Then
		PaymentMethod = "NonCash";
	ElsIf Object.PaymentMethodOfPaymentRequest = Enums.PaymentForms.CashAccountPayment_ Then
		PaymentMethod = "Cash"
	Else
		PaymentMethod = "InAnyForm";
	EndIf;
	
	SetHintWhenOrderingTickets(ThisObject, False);
	SetHintWhenOrderingTickets(ThisObject, True);
	SetAccommodationHint(ThisObject);
	
	Items.ExpensesBudgetFlowItem.Visible = Documents.ApplicationForBusinessTrip.UseBDRLimits();
	
EndProcedure

&AtServer
Procedure FillContactInformation()
	
	Object.Phone = "";
	Object.Email = "";
	
	If ValueIsFilled(Object.Employee) Then
		
		CIObjects = New Array;
		CIObjects.Add(Object.Employee);
		
		TypesOfCI = New Array;
		TypesOfCI.Add(Enums.ContactInformationTypes.Phone);
		TypesOfCI.Add(Enums.ContactInformationTypes.Email);
		
		KI = ContactsManager.ObjectsContactInformation(CIObjects, TypesOfCI);
		
		If KI.Count() Then
			For Each CIRow In KI Do
				If CIRow.Type = Enums.ContactInformationTypes.Phone Then
					Object.Phone = CIRow.Presentation;
				ElsIf CIRow.Type = Enums.ContactInformationTypes.Email Then
					Object.Email = CIRow.Presentation;
				EndIf;
				If ValueIsFilled(Object.Phone) And ValueIsFilled(Object.Email) Then
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function HeadingSecondedEmployees()
	
	EmployeesByLine = New Array;
	
	DetailsOfEmployees = Common.ObjectsAttributeValue(
		Object.TravellingEmployees.Unload(, "Employee").UnloadColumn("Employee"), "Description");
	For Each KeyAndValue In DetailsOfEmployees Do
		EmployeesByLine.Add(KeyAndValue.Value);
	EndDo;
	
	If Not EmployeesByLine.Count() Then
		EmployeesByLine.Add(NStr("vi = '<chỉ ra nhân viên>';
								|ru = '<указать сотрудников>';
								|en = '<specify employees>'; fa = '<specify employees>';
								|it = '<indicare dipendenti>';
								|pl = '<wskaż pracowników>';
								|tr = '<çalışanları belirt>'"));
	EndIf;
	
	Return StrConcat(EmployeesByLine, "; ");
	
EndFunction

&AtServer
Procedure InitializeBookingElements()

	BookingElements = New Map;
	BookingElements.Insert("BookDepartureToDestination", New Structure);
	BookingElements.Insert("BookArrivalToDestination", New Structure);
	BookingElements.Insert("BookDestinationTransferLocation", New Structure);
	BookingElements.Insert("BookReturnDeparture", New Structure);
	BookingElements.Insert("BookArrivalBack", New Structure);
	BookingElements.Insert("BookReturnTransferLocation", New Structure);
	BookingElements.Insert("BookAccommodation_", New Structure);
	
	ParametersOfBookingElements = New FixedMap(BookingElements);
	
	IDs = New Map;
	IDs.Insert("BookDepartureToDestination", "BookDepartureToDestinationID");
	IDs.Insert("BookArrivalToDestination", "BookArrivalToDestinationID");
	IDs.Insert("BookDestinationTransferLocation", "BookDestinationTransferLocationID");
	IDs.Insert("BookReturnDeparture", "BookReturnDepartureID");
	IDs.Insert("BookArrivalBack", "BookArrivalBackID");
	IDs.Insert("BookReturnTransferLocation", "BookReturnTransferLocationID");
	IDs.Insert("BookAccommodation_", "BookAccommodationsID");
	
	IdsOfBookingElements = New FixedMap(IDs);

EndProcedure

&AtClientAtServerNoContext
Function InitializeBookingParameters()

	BookingParameters = New Structure;
	BookingParameters.Insert("BookPlane", False);
	BookingParameters.Insert("BookTrain", False);
	BookingParameters.Insert("BookTransfer", False);
	BookingParameters.Insert("BookAccommodation", False);
	
	Return BookingParameters

EndFunction

&AtClientAtServerNoContext
Procedure FillInBookingParameters(Form, FormItem, ReverseDirection = False)

	If TypeOf(FormItem) = Type("FormGroup") Then
		
		For Each CurrentItem In FormItem.ChildItems Do
			ChangeParameterOfBookingElement(Form, CurrentItem.Name, ReverseDirection);
			FillInBookingParameters(Form, CurrentItem, ReverseDirection);
		EndDo;
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ChangeParameterOfBookingElement(Form, TagName, ReverseDirection)

	SetOfElements = Form.ParametersOfBookingElements; // FixedMap
	ItemParameters = SetOfElements.Get(TagName);
	
	If ItemParameters <> Undefined Then
		
		BookingElements = New Map(Form.ParametersOfBookingElements);
		Properties = BookingProperties(Form, ReverseDirection);
		BookingParameters = InitializeBookingParameters();
		
		ExcludeProperties = UnchangedParametersOfBookingElement(TagName);
		FillPropertyValues(BookingParameters, Properties, , ExcludeProperties);
		
		BookingElements.Insert(TagName, BookingParameters);
		
		Form.ParametersOfBookingElements = New FixedMap(BookingElements);
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function BookingProperties(Form, ReverseDirection)

	BookingParameters = New Structure;
	
	If Not ReverseDirection Then
		
		BookingParameters.Insert("Book", Form.Object.BookTicketsToDestination);
		BookingParameters.Insert("BookPlane", Form.Object.BookAirlineToDestination);
		BookingParameters.Insert("BookTrain", Form.Object.BookTrainToDestination);
		BookingParameters.Insert("BookTransfer", Form.Object.BookTransferToDestination);
		BookingParameters.Insert("ElementOfDeparture", Form.Items.BookDepartureToDestination);
		BookingParameters.Insert("ElementArrival", Form.Items.BookArrivalToDestination);
		BookingParameters.Insert("TransferItem", Form.Items.BookDestinationTransferLocation);
		
	Else
		
		BookingParameters.Insert("Book", Form.Object.BookReturnTickets);
		BookingParameters.Insert("BookPlane", Form.Object.BookAirlineBack);
		BookingParameters.Insert("BookTrain", Form.Object.BookTrainBack);
		BookingParameters.Insert("BookTransfer", Form.Object.BookTransferBack);
		BookingParameters.Insert("ElementOfDeparture", Form.Items.BookReturnDeparture);
		BookingParameters.Insert("ElementArrival", Form.Items.BookArrivalBack);
		BookingParameters.Insert("TransferItem", Form.Items.BookReturnTransferLocation);
		
	EndIf;
	
	BookingParameters.Insert("BookAccommodation", Form.Object.BookAccommodation);
	
	Return BookingParameters;

EndFunction

&AtClient
Function ElementInGroup(Item, GroupName)

	If TypeOf(Item.Parent) = Type("FormGroup") Then
		
		If Item.Parent.Name = GroupName Then
			Return True;
		Else
			Return ElementInGroup(Item.Parent, GroupName);
		EndIf;
		
	Else
		Return False;
	EndIf;

EndFunction

&AtClientAtServerNoContext
Function UnchangedParametersOfBookingElement(TagName)

	ExcludeProperties = "";
	
	If TagName = "BookDepartureToDestination"
		Or TagName = "BookArrivalToDestination"
		Or TagName = "BookReturnDeparture"
		Or TagName = "BookArrivalBack" Then
		ExcludeProperties = "BookTransfer, BookAccommodation";
	ElsIf TagName = "BookAccommodation_" Then
		ExcludeProperties = "BookPlane, BookTrain, BookTransfer";
	ElsIf TagName = "BookDestinationTransferLocation"
		Or TagName = "BookReturnTransferLocation" Then
		ExcludeProperties = "BookAccommodation";
	EndIf;
	
	Return ExcludeProperties;

EndFunction

&AtClient
Procedure ProcessingSelectionOfBookingObjects(TagName, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	
	Object[TagName] = ChoiceData.Presentation;
	Id = IdsOfBookingElements.Get(TagName);
	
	If Id <> Undefined Then
		Object[Id] = ChoiceData.Code;
	EndIf;

EndProcedure

&AtClient
Procedure EndOfEnteringTextOfBookingElements(Text, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	Value = CompositionOfBookingElement("", Text);
	ChoiceData.Add(Value, Text);

EndProcedure

&AtServerNoContext
Function CompositionOfBookingElement(Code, Presentation, ThisIsTheRegion = False)

	ElementStructure = New Structure("Code, Presentation");
	ElementStructure.Insert("Code", Code);
	ElementStructure.Insert("Presentation", Presentation);
	ElementStructure.Insert("ThisIsTheRegion", ThisIsTheRegion);
	
	Return ElementStructure;

EndFunction

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_StartDate" Then
		StartDateOnChange(Items.StartDate);
	ElsIf Item.Name = "sh_ShamsiInput_EndDate" Then
		EndDateOnChange(Items.EndDate);
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
