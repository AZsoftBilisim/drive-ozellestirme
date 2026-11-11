////////////////////////////////////////////////////////////////////////////////
// The module "Provision in documents (Client)" contains procedures and functions
// that serve the operation of the mechanism for reserving and ensuring the needs for documents on the client"
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Service forms of documents

// Checks whether the result of closing the "Request for quantity and Series" processing form needs to be processed.
//
// Parameters:
//  ValueSelected - Undefined,Structure - the result of closing the "Request for quantity and series" form.
//
// Returns:
//  Boolean - True if processing is required, false otherwise.
//
Function ThereAreSelectedProducts(ValueSelected) Export
	
	If Not ValueIsFilled(ValueSelected) Then
		Return False;
	EndIf;
	
	If ValueSelected.SelectedGoods.Count() = 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// The handler after the order is recorded.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  HandlerName - String - the name of the waiting handler procedure for verifying the completion
//                            of inventory allocation tasks in the order form.
//
Procedure AfterWrite(Form, HandlerName) Export
	
	InternalParameters = Form.AvailableRemainingEmbeddingOptions.InternalParameters;
	If InternalParameters.NeedAvailabilityUpdateHandler Then
		
		InternalParameters.NeedAvailabilityUpdateHandler = False;
		Form.AttachIdleHandler(HandlerName, InternalParameters.IntervalForStartingHandler, True);
		
	EndIf;
	
EndProcedure

// Checks whether the "Available" column or the State hyperlink needs to be updated after the order is recorded.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  HandlerName - String - the name of the waiting handler procedure for verifying the completion
//                            of inventory allocation tasks in the order form.
//  Error - Boolean - the function is set to true if inventory could not be distributed.
//
// Returns:
//  Boolean - True if processing is required, false otherwise.
//
Function NeedToUpdateAvailabilityAfterRecording(Form, HandlerName, Error) Export
	
	InternalParameters = Form.AvailableRemainingEmbeddingOptions.InternalParameters;
	Orders = InternalParameters.OrdersToUpdateAvailability;
	NeedToUpdate = SupplyInDocumentsServerCall.NeedToUpdateAvailabilityAfterRecording(Orders);
	If Not NeedToUpdate Then
		If InternalParameters.IntervalForStartingHandler > 15 Then
			NeedToUpdate = True;
			Error = True;
		Else
			Form.AttachIdleHandler(HandlerName, InternalParameters.IntervalForStartingHandler, True);
		EndIf;
	EndIf;
	
	Return NeedToUpdate;
	
EndFunction

// Checks whether the "Available" column needs to be updated after the order is recorded.
// Call only in conjunction with the need to update the availability of the after-recording.
// Parameters:
//  Form - ClientApplicationForm - order form.
// Returns:
//  Boolean - True if processing is required, false otherwise.
//
Function ToUpdateColumnAvailableAfterInventoryAllocation(Form) Export
	
	InternalParameters = Form.AvailableRemainingEmbeddingOptions.InternalParameters;
	Return InternalParameters.ToUpdateColumnAvailableAfterInventoryAllocation;
	
EndFunction

// Constructor of the structure of the parameters of the security status form.
//
// Parameters:
//  ContextOfUse - String - the symbol of the place of opening of the form of the State of the provision:
//                                   "ORDER", if the call is from the form of the completed order,
//                                   "LIST of ORDERS", if the call is from the list of orders,
//                                   "TABLE", if the call is from the form of the pending order,
//                                   "SECTION", if the call is from the section.
//
// Returns:
//  Structure - structure with fields:
//  * ContextOfUse - String - context of use.
//  * OrderDocument - Undefined - a reference to an order if the context is "ORDER" or "TABLE".
//  * Orders - Undefined - array of orders, passed if the context is "ORDER LISTS".
//  * AddressOfTheMovementTable - Undefined - address in the storage, if the context is "TABLE".
//  * ReadOnly - Boolean - if false, then commands to change the object will not be available.
//  * AvailableRemainingDocumentParameters - Undefined
//                                       - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions.
//  * AcceptableSecurityOptions - Undefined - an array of support options that affects the availability of commands for setting actions
//  * OrdersMotionRecorders - Undefined - the array is used in the context of "TABLE" if the passed parameter Order is not a motion logger.
//  * StageOfDynamicOrderStructure - Boolean - indicates whether the form is called from the production stage of the dynamic order structure in the "TABLE" context.
//
Function OrderSecurityStateFormParameters(ContextOfUse) Export
	
	FormParameters = New Structure();
	FormParameters.Insert("ContextOfUse", ContextOfUse);
	FormParameters.Insert("OrderDocument", Undefined);
	FormParameters.Insert("Orders", Undefined);
	FormParameters.Insert("AddressOfTheMovementTable", Undefined);
	FormParameters.Insert("ReadOnly", False);
	FormParameters.Insert("AvailableRemainingDocumentParameters", Undefined);
	FormParameters.Insert("AcceptableSecurityOptions", Undefined);
	FormParameters.Insert("OrdersMotionRecorders", Undefined);
	FormParameters.Insert("StageOfDynamicOrderStructure", False);
	Return FormParameters;
	
EndFunction

// It is used to limit the commands for setting actions in the "Software State" processing.
// Returns:
//  Map of Boolean - True if the security option is acceptable for installation in the document.
Function AllValidSecurityOptions() Export
	
	AllVariants = New Map();
	AllVariants.Insert(PredefinedValue("Enum.SupplyOptions.Ship"), True);
	AllVariants.Insert(PredefinedValue("Enum.SupplyOptions.FromWarehouse"), True);
	AllVariants.Insert(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"), True);
	AllVariants.Insert(PredefinedValue("Enum.SupplyOptions.ToSupply"), True);
	AllVariants.Insert(PredefinedValue("Enum.SupplyOptions.NotRequired"), True);
	Return AllVariants;
	
EndFunction

// Handler for clicking the security status hyperlink in the order form.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//
// Returns:
//  See OrderSecurityStateFormParameters
//
Function SecurityStatusHyperlinkClick(Form) Export
	
	If Form.Modified
			Or Not Form.AvailableRemainingEmbeddingOptions.InternalParameters.ReadyForSupply
			Or Not ValueIsFilled(Form.Object.Ref)
			Or Not SupplyInDocumentsServerCall.HyperlinkStateOfProvisionClickDocumentCompleted(Form.Object.Ref) Then
		
		FormParameters = OrderSecurityStateFormParameters("TABLE");
		FormParameters.OrderDocument = Form.Object.Ref;
		
	Else
		
		FormParameters = OrderSecurityStateFormParameters("ORDERDOCUMENT");
		FormParameters.OrderDocument = Form.Object.Ref;
		
	EndIf;
	
	FormParameters.ReadOnly = Form.ReadOnly;
	FormParameters.AvailableRemainingDocumentParameters =
		AvailableRemainingDocumentParameters(Form);
	
	Return FormParameters;
	
EndFunction

// Sets the necessary hyperlink in the order to go to the security state.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//
Procedure ConfigureHyperlinkedSoftwareState(Form) Export
	
	If Form.Modified Then
		
		Object = Form.Object; // DocumentObject
		HyperlinkProperties = SupplyInDocumentsServerCall.PropertiesOfSoftwareStateHyperlink(
			Form.Modified,
			Object.Ref,
			Form.AvailableRemainingEmbeddingOptions.InternalParameters.ReadyForSupply);
			
		Items = Form.Items;
		ItemsNames = Form.AvailableRemainingEmbeddingOptions.ItemsNames;
		Items[ItemsNames["PagesHyperlinkSoftwareStatus"]].CurrentPage
			= Items[ItemsNames[HyperlinkProperties.PageName]];
		
	EndIf;

EndProcedure

// Sets the required hyperlink in the order to navigate to the State Of the Provision for the recorded document.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  ProblemWithStartingJob - Boolean - True if, as a result of queries, it is determined that there are problems with starting the distribution of spare parts.
//
Procedure ConfigureHyperlinksSupplyForecastAfterRecording(Form, ProblemWithStartingJob) Export
	
	Object = Form.Object; // DocumentObject
	HyperlinkProperties = SupplyInDocumentsServerCall.PropertiesOfSoftwareStateHyperlink(
		False,
		Object.Ref,
		Form.AvailableRemainingEmbeddingOptions.InternalParameters.ReadyForSupply,
		ProblemWithStartingJob);
	Items = Form.Items;
	ItemsNames = Form.AvailableRemainingEmbeddingOptions.ItemsNames;
	Items[ItemsNames["PagesHyperlinkSoftwareStatus"]].CurrentPage
		= Items[ItemsNames[HyperlinkProperties.PageName]];
	Items[ItemsNames[HyperlinkProperties.HyperlinkName]].Title = HyperlinkProperties.Title;

EndProcedure

// The handler for changing the flag Separately in the order line.
//
// Parameters:
//  CurrentData - FormDataCollectionItem - order line.
//
Procedure WithAssignmentOnChange(CurrentData) Export
	
	CurrentData.SupplyOption = ProvisionInDocumentsClientServer.WithAssignmentOnChange(
		CurrentData.WithAssignment,
		CurrentData.SupplyOption,
		CurrentData.ItemsType);
	
EndProcedure

// Returns the text " filling in security"
//
// Returns:
//   String - the text "Filling in the collateral".
//
Function TextFillingInSecurity() Export
	Return NStr("vi = 'Điền đảm bảo';
				|ru = 'Заполнение обеспечения';
				|en = 'Fill in supply'; fa = 'تکمیل تأمین';
				|it = 'Compilazione di approvvigionamento';
				|pl = 'Wypełnienie zaopatrzenia';
				|tr = 'Satın alma girişi'");
EndFunction

// Depending on the executed command, the software in the order form generates the text of the user's notification.
// 
// Parameters:
//  Mode - String - command execution mode.
//
// Returns:
//   String - the text of the notification about the filling of the warehouse, action or series in the order.
//
Function TextProcessingAlertsWarehouseAndBatchSelection(Mode) Export
	
	Text = Undefined;
	If Mode = ProvisionInDocumentsClientServer.WarehouseSelectionMode() Then
		Text = NStr("vi = 'Điền kho bãi';
					|ru = 'Заполнение склада';
					|en = 'Warehouse population'; fa = 'Warehouse population';
					|it = 'Compilazione del magazzino';
					|pl = 'Wypełnienie magazynu';
					|tr = 'Ambarın doldurulması'");
	ElsIf Mode = ProvisionInDocumentsClientServer.ActionSelectionMode() Then
		Text = NStr("vi = 'Điền thao tác';
					|ru = 'Заполнение действия';
					|en = 'Action population'; fa = 'Action population';
					|it = 'Compilazione dell''azione';
					|pl = 'Wypełnienie działania';
					|tr = 'İşlem doldurma'");
	ElsIf Mode = ProvisionInDocumentsClientServer.SeriesSelectionMode() Then
		Text = NStr("vi = 'Điền sê-ri';
					|ru = 'Заполнение серий';
					|en = 'Batch population'; fa = 'Batch population';
					|it = 'Compilazione delle serie';
					|pl = 'Wypełnienie serii';
					|tr = 'Parti doldurma'");
	EndIf;
	Return Text;
	
EndFunction

// Shows a question about whether to fill in whole or fractional packages when executing
// the "Ship" or "Reserve" commands on the order form.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  Collection - FormDataCollection - the tabular part of the order in which the provisioning commands are executed.
//  Result - See ProvisionInDocumentsServer.ProvidingSetActionResultStructure
//  NameOfNotificationProcedure - String - notification procedure in the order form to which control will be transferred after the response.
//
// Returns:
//  Boolean - True if the question is asked, false if the question was not asked.
//
Function  ShowIssueOfFillingSoftwareWithWholePackages(Form, Collection, Result, NameOfNotificationProcedure) Export
	
	If Not Result.AskingAboutFillingWithWholePackages Then
		Return False;
	EndIf;
	
	CallbackDescription = New CallbackDescription(NameOfNotificationProcedure, Form, Result);
	
	QueryText = NStr("vi = 'Do kết quả điền, trong nhiều dòng số lượng đóng gói sẽ trở thành phân số.';
					|ru = 'В результате заполнения в некоторых строках количество упаковок станет дробным.';
					|en = 'Population will result in fractional number of packaging units in some lines.'; fa = 'Population will result in fractional number of packaging units in some lines.';
					|it = 'In seguito a compilazione la quantità di confezioni in alcune righe diventerà frazionaria.';
					|pl = 'W rezultacie wypełnienia w niektórych wierszach ilość opakowań stanie ułamkową.';
					|tr = 'Bazı satırların doldurulması sonucunda paketleme ünitesi sayısı kesirli hale gelecektir.'");
	
	ButtonsList = New ValueList();
	ButtonsList.Add("FractionalPackings", NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Continue';
												|tr = 'Devam et'"));
	ButtonsList.Add("INTEGERS_UPACKAGES",   NStr("vi = 'Chỉ điền đóng gói toàn bộ';
												|ru = 'Заполнить только целыми упаковками';
												|en = 'Populate with whole packaging units only'; fa = 'Populate with whole packaging units only';
												|it = 'Compilare solo con le confezioni intere';
												|pl = 'Wypełnij tylko całymi opakowaniami';
												|tr = 'Sadece paketleme üniteleri ile doldur'"));
	
	QuestionTitle = NStr("vi = 'Điền đảm bảo';
						|ru = 'Заполнение обеспечения';
						|en = 'Fill in supply'; fa = 'تکمیل تأمین';
						|it = 'Compilazione di approvvigionamento';
						|pl = 'Wypełnienie zaopatrzenia';
						|tr = 'Satın alma girişi'");
	
	FormParameters = TMCommonUseClient.FormParametersQuestionYesNoCancel();
	FormParameters.QueryText = QueryText;
	FormParameters.ButtonsList = ButtonsList;
	FormParameters.QuestionTitle = QuestionTitle;
	FormParameters.ShowCloseButton = True;
	DescriptionOfNotificationIntermediate = New CallbackDescription("NotificationProcessingIsIntermediate",
		ThisObject, CallbackDescription);
	OpenForm("CommonForm.QuestionYesNoCancel", FormParameters, Form, , , , DescriptionOfNotificationIntermediate);
	Return True;
	
EndFunction

// Shows a question about whether to remove the "Ship by one date" flag when executing
// the "Ship" commands in the order form.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  Collection - FormDataCollection - the tabular part of the order in which the provisioning commands are executed.
//  Result - See ProvisionInDocumentsServer.ProvidingSetActionResultStructure
//  NameOfNotificationProcedure - String - notification procedure in the order form to which control will be transferred after the response.
//
// Returns:
//  Boolean - True if the question is asked, false if the question was not asked.
//
Function ShowQuestionUncheckShipByOneDate(Form, Collection, Result, NameOfNotificationProcedure) Export
	
	If Not Result.UncheckShipByOneDateFlag Then
		Return False;
	EndIf;
	
	CallbackDescription = New CallbackDescription(NameOfNotificationProcedure, Form, Result);
	
	QuestionTextTemplate = NStr("vi = 'Ngày giao hàng của các dòng được điền %1, ngày giao hàng của các dòng còn lại %2.
		|Có thể giao tất cả vào một ngày %1, có thể giao từng phần.';
		|ru = 'Дата отгрузки заполняемых строк %1, дата отгрузки остальных строк %2.
		|Можно отгрузить все одной датой %1, можно отгружать частями.';
		|en = 'Shipment date of the populated lines %1, shipment date of other lines %2.
		|All items can be shipped at once on %1, or in installments.'; fa = 'Shipment date of the populated lines %1, shipment date of other lines %2.
		|All items can be shipped at once on %1, or in installments.';
		|it = 'Data di spedizione delle righe compilate %1, data di spedizione delle altre righe %2.
		|È possibile spedire in unica data %1, è possibile spedire in parti.';
		|pl = 'Data wysłania wypełnianych wierszy %1, data wysłania pozostałych wierszy %2.
		|Można wysłać wszystkie w jednym dniu %1, można wysyłać częściami.';
		|tr = 'Doldurulan satırların sevkiyat tarihi %1, kalan satırların sevkiyat tarihi %2''dir.
		|Her şey aynı tarihte %1 sevk edilebilinir, parça parça sevk edebilirsiniz.'");
	
	OldShipmentDateLine = Format(Result.TheShipmentDateOfAllLinesIsASingleDate, "DLF=D");
	NewShipmentDateLine = Format(Result.DateOfShipmentOfCompletedLines, "DLF=D");
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionTextTemplate,
		NewShipmentDateLine,
		?(Result.TheShipmentDateOfAllLinesIsASingleDate = '00010101', NStr("vi = 'chưa chỉ ra';
																			|ru = 'не указана';
																			|en = 'not specified'; fa = 'مشخص نشده';
																			|it = 'non specificato';
																			|pl = 'nie określona';
																			|tr = 'belirtilmedi'"), OldShipmentDateLine),
		NewShipmentDateLine);
	
	ButtonsList = New ValueList();
	ButtonTemplate = NStr("vi = 'Giao hàng trong một ngày (%1)';
							|ru = 'Отгрузить одной датой (%1)';
							|en = 'Same-date shipment (%1)'; fa = 'Same-date shipment (%1)';
							|it = 'Spedisci una data (%1)';
							|pl = 'Wyślij w jednym dniu (%1)';
							|tr = 'Aynı tarihte sevk et (%1)'");
	ButtonText = StringFunctionsClientServer.SubstituteParametersToString(ButtonTemplate, NewShipmentDateLine);
	ButtonsList.Add("SHIPPED_ODATE_DROBNY_PACKAGES", ButtonText);
	ButtonsList.Add("SHIPPING_PARTICIPATION_PACKAGES", NStr("vi = 'Giao hàng từng phần';
															|ru = 'Отгружать частями';
															|en = 'Ship in installments'; fa = 'Ship in installments';
															|it = 'Spedire in parti';
															|pl = 'Wysyłaj częściowo';
															|tr = 'Parçalar halinde sevk et'"));
	
	QuestionTitle = NStr("vi = 'Thiết lập thao tác';
						|ru = 'Установка действий';
						|en = 'Setting actions'; fa = 'Setting actions';
						|it = 'Impostazione delle azioni';
						|pl = 'Ustawienie działań';
						|tr = 'İşlem ayarlama'");
	
	FormParameters = TMCommonUseClient.FormParametersQuestionYesNoCancel();
	FormParameters.QueryText = QueryText;
	FormParameters.ButtonsList = ButtonsList;
	FormParameters.QuestionTitle = QuestionTitle;
	FormParameters.ShowCloseButton = True;
	DescriptionOfNotificationIntermediate = New CallbackDescription("NotificationProcessingIsIntermediate",
		ThisObject, CallbackDescription);
	OpenForm("CommonForm.QuestionYesNoCancel", FormParameters, Form, , , , DescriptionOfNotificationIntermediate);
	
	Return True;
	
EndFunction

// Shows a question about whether to remove the "Ship by one date" flag when executing
// the "Ship" commands in the order form after the question about filling in whole or fractional packages.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  Collection - FormDataCollection - the tabular part of the order in which the provisioning commands are executed.
//  Result - See ProvisionInDocumentsServer.ProvidingSetActionResultStructure
//  Response - String - result of the answer to the question about filling with integer or fractional packages
//  NameOfNotificationProcedure - String - notification procedure in the order form to which control will be transferred after the response.
//
// Returns:
//  Boolean - True if the question is asked, false if the question was not asked.
//
Function ShowQuestionUncheckShipOneDateAfterQuestion(Form, Collection, Result, Response, NameOfNotificationProcedure) Export
	
	If Response = "FractionalPackings" Then
		Return ShowQuestionUncheckShipByOneDate(Form, Collection, Result, NameOfNotificationProcedure);
	EndIf;
		
	If Not Result.RemoveFlagShipOneDateInWholePackages Then
		Return False;
	EndIf;

	CallbackDescription = New CallbackDescription(NameOfNotificationProcedure, Form, Result);
	
	QuestionTextTemplate = NStr("vi = 'Ngày giao hàng của các dòng được điền %1, ngày giao hàng của các dòng còn lại %2.
		|Có thể giao tất cả vào một ngày %1, có thể giao từng phần.';
		|ru = 'Дата отгрузки заполняемых строк %1, дата отгрузки остальных строк %2.
		|Можно отгрузить все одной датой %1, можно отгружать частями.';
		|en = 'Shipment date of the populated lines %1, shipment date of other lines %2.
		|All items can be shipped at once on %1, or in installments.'; fa = 'Shipment date of the populated lines %1, shipment date of other lines %2.
		|All items can be shipped at once on %1, or in installments.';
		|it = 'Data di spedizione delle righe compilate %1, data di spedizione delle altre righe %2.
		|È possibile spedire in unica data %1, è possibile spedire in parti.';
		|pl = 'Data wysłania wypełnianych wierszy %1, data wysłania pozostałych wierszy %2.
		|Można wysłać wszystkie w jednym dniu %1, można wysyłać częściami.';
		|tr = 'Doldurulan satırların sevkiyat tarihi %1, kalan satırların sevkiyat tarihi %2''dir.
		|Her şey aynı tarihte %1 sevk edilebilinir, parça parça sevk edebilirsiniz.'");
	
	OldShipmentDateLine = Format(Result.TheShipmentDateOfAllLinesIsASingleDate, "DLF=D");
	NewShipmentDateLine = Format(Result.DateOfShipmentOfCompletedLines, "DLF=D");
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionTextTemplate,
		NewShipmentDateLine,
		?(Result.TheShipmentDateOfAllLinesIsASingleDate = '00010101', NStr("vi = 'chưa chỉ ra';
																			|ru = 'не указана';
																			|en = 'not specified'; fa = 'مشخص نشده';
																			|it = 'non specificato';
																			|pl = 'nie określona';
																			|tr = 'belirtilmedi'"), OldShipmentDateLine),
		NewShipmentDateLine);
	
	ButtonsList = New ValueList();
	ButtonTemplate = NStr("vi = 'Giao hàng trong một ngày (%1)';
							|ru = 'Отгрузить одной датой (%1)';
							|en = 'Same-date shipment (%1)'; fa = 'Same-date shipment (%1)';
							|it = 'Spedisci una data (%1)';
							|pl = 'Wyślij w jednym dniu (%1)';
							|tr = 'Aynı tarihte sevk et (%1)'");
	ButtonText = StringFunctionsClientServer.SubstituteParametersToString(ButtonTemplate, NewShipmentDateLine);
	ButtonsList.Add("SHIPPED_ODATE_SELECT_PACKAGES", ButtonText);
	ButtonsList.Add("SHIPPING_PARTICELS_SELECT_PACKAGES", NStr("vi = 'Giao hàng từng phần';
																|ru = 'Отгружать частями';
																|en = 'Ship in installments'; fa = 'Ship in installments';
																|it = 'Spedire in parti';
																|pl = 'Wysyłaj częściowo';
																|tr = 'Parçalar halinde sevk et'"));
	
	QuestionTitle = NStr("vi = 'Thiết lập thao tác';
						|ru = 'Установка действий';
						|en = 'Setting actions'; fa = 'Setting actions';
						|it = 'Impostazione delle azioni';
						|pl = 'Ustawienie działań';
						|tr = 'İşlem ayarlama'");
	FormParameters = TMCommonUseClient.FormParametersQuestionYesNoCancel();
	FormParameters.QueryText = QueryText;
	FormParameters.ButtonsList = ButtonsList;
	FormParameters.QuestionTitle = QuestionTitle;
	FormParameters.ShowCloseButton = True;
	DescriptionOfNotificationIntermediate = New CallbackDescription("NotificationProcessingIsIntermediate",
		ThisObject, CallbackDescription);
	OpenForm("CommonForm.QuestionYesNoCancel", FormParameters, Form, , , , DescriptionOfNotificationIntermediate);

	Return True;
	
EndFunction

// Inserts the parameters "Maximum Upload date" and "Minimum Upload date" into the structure, based on the shipment dates for the rows
// of the tabular part of the document with the "Ship"action.
//
// Parameters:
//  Structure - Structure - the structure to insert the parameter into.
//  Goods - FormDataCollection - the tabular part of the order.
//  TheShipmentDateOfAllLinesIsASingleDate - Date, Undefined - the date of shipment specified in the header of the document, if any.
//
Procedure InsertParametersOfSelectedProducts(Structure, Goods, TheShipmentDateOfAllLinesIsASingleDate) Export
	
	If Not ValueIsFilled(TheShipmentDateOfAllLinesIsASingleDate) Then
		Return;
	EndIf;
	
	MaximumShipmentDate = '00010101';
	MinimumShipmentDate = '39990101';
	ShipmentDateForReservation = Max(BegOfDay(CommonClient.SessionDate()), TheShipmentDateOfAllLinesIsASingleDate);
	For Each Item In Goods Do
		
		ThisIsShipment = Item.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
		DateOfShipment = Item.DateOfShipment;
		If ThisIsShipment And Not ValueIsFilled(DateOfShipment) Then
			DateOfShipment = ShipmentDateForReservation;
		EndIf;
		
		MaximumShipmentDate = Max(MaximumShipmentDate, DateOfShipment);
		If DateOfShipment > '00010101' Then
			MinimumShipmentDate = Min(MinimumShipmentDate, DateOfShipment);
		EndIf;
		
	EndDo;
	If MinimumShipmentDate = '39990101' Then
		MinimumShipmentDate = '00010101';
	EndIf;
	
	Structure.Insert("MaximumShipmentDate", MaximumShipmentDate);
	Structure.Insert("MinimumShipmentDate",  MinimumShipmentDate);
	
EndProcedure

// Returns the parameters of embedding the software subsystem in the order, cached in the document form.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//
// Returns:
//  Structure - structure with fields:
//   * EmbeddingParameters - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//   * ProgramObjectData - See ProvisionInDocumentsClientServer.ProgramObjectData.
//
Function AvailableRemainingDocumentParameters(Form) Export
	
	ProgramObjectData = Undefined;
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	
	CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(Form, EmbeddingParameters);
	TabSectionRow = Undefined;
	If CollectionOnForm.Count() > 0 Then
		TabSectionRow = CollectionOnForm[0];
	EndIf;
		ActionParameters = New Structure("Form,EmbeddingParameters", Form, EmbeddingParameters);
		ProgramObjectData = ProvisionInDocumentsClientServer.ProgramObjectData(ActionParameters, TabSectionRow);
	Return New Structure("EmbeddingParameters,ProgramObjectData",
		EmbeddingParameters, ProgramObjectData);
	
EndFunction

// A structure for processing shipment dates after executing the provisioning commands in the order.
//
// Parameters:
//  Response - String - the answer to the need to remove the ship by one date flag in the order form.
//
// Returns:
//  Structure - structure with fields:
//   * UncheckShipByOneDateFlag - Boolean - True if you need to remove the shipping flag with a single date.
//   * FillShippingDateWithSingleDate - Boolean - True if you do not need to remove the shipment flag with a single date.
//
Function ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response) Export
	
	FillParameters = New Structure();
	FillParameters.Insert("UncheckShipByOneDateFlag",    Response = "DialogReturnCode_Yes");
	FillParameters.Insert("FillShippingDateWithSingleDate", Response = "DialogReturnCode_No");
	Return FillParameters;
	
EndFunction

// Shows the question about whether to remove the "Ship on one date" flag when setting the security action in
// the order line if the form for specifying warehouses and series opens.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  ValueSelected - Structure - the result of selecting an action in the form of processing the "Request for the number of criteria".
//  FormParameters - See ProvisionInDocumentsServer.SoftwareSelectionParameters
//  NameOfNotificationProcedure - String - notification procedure in the order form to which control will be transferred after the response.
//
Procedure ShowQuestionUncheckShipByOneDateAfterSelectingCollateral(Form, ValueSelected, FormParameters, NameOfNotificationProcedure) Export
	
	Parameters = New Structure("ValueSelected,FormParameters", ValueSelected, FormParameters);
	
	CallbackDescription = New CallbackDescription(NameOfNotificationProcedure, Form, Parameters);
	
	ParametersForSettingShipmentDates = ValueSelected.ParametersForSettingShipmentDates;
	If FormParameters.Mode = ProvisionInDocumentsClientServer.ActionSelectionMode()
		And ParametersForSettingShipmentDates.TheShipmentDateOfAllLinesIsASingleDate <> Undefined
		And ParametersForSettingShipmentDates.TheShipmentDateOfAllLinesIsASingleDate < ParametersForSettingShipmentDates.DateWhenTheNewLinesWereShipped Then
		
		If ParametersForSettingShipmentDates.FillInDateOfShipmentOfAllLinesWithDateOfNewLines Then
			RunCallback(CallbackDescription, "DialogReturnCode_No");
		Else
			ShowQuestionAboutShippingByOneDate(
				CallbackDescription,
				ParametersForSettingShipmentDates.TheShipmentDateOfAllLinesIsASingleDate,
				ParametersForSettingShipmentDates.DateWhenTheNewLinesWereShipped,
				ParametersForSettingShipmentDates.DateWhenTheNewLinesWereShipped,
				NStr("vi = 'Chọn hiệu lực';
					|ru = 'Выбор действия';
					|en = 'Select action'; fa = 'انتخاب اقدام';
					|it = 'Scelta dell''azione';
					|pl = 'Wybór czynności';
					|tr = 'Eylem seçimi'"));
		EndIf;
			
	Else
		
		RunCallback(CallbackDescription);
		
	EndIf;
	
EndProcedure

// Shows a question about whether to remove the "Ship on one date" flag after closing the product selection form.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  SelectionData_1 - Structure - the result of closing the product selection form in the document
//  NameOfNotificationProcedure - String - notification procedure in the order form to which control will be transferred after the response.
//
Procedure ShowQuestionUncheckShipOneDateAfterSelection(Form, SelectionData_1, NameOfNotificationProcedure) Export
	
	CallbackDescription = New CallbackDescription(NameOfNotificationProcedure, Form, SelectionData_1);
	
	If ValueIsFilled(SelectionData_1.TheShipmentDateOfAllLinesIsASingleDate) And SelectionData_1.MinimumShipmentDate <> SelectionData_1.MaximumShipmentDate Then
		
		ButtonsList = New ValueList();
		QueryText = NStr("vi = 'Ngày giao hàng của các dòng đã chọn khác nhau.';
						|ru = 'Даты отгрузки подобранных строк различаются.';
						|en = 'The shipment dates of the picked lines are different.'; fa = 'The shipment dates of the picked lines are different.';
						|it = 'Le date di spedizione delle righe selezionate differiscono.';
						|pl = 'Daty wysyłki wybranych wierszy różnią się.';
						|tr = 'Seçilen satırlar için sevkiyat tarihleri ​​değişiklik gösterir.'");
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Giao hàng từng phần';
													|ru = 'Отгружать частями';
													|en = 'Ship in installments'; fa = 'Ship in installments';
													|it = 'Spedire in parti';
													|pl = 'Wysyłaj częściowo';
													|tr = 'Parçalar halinde sevk et'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		
		QuestionTitle = NStr("vi = 'Chọn hàng hóa';
							|ru = 'Подбор товаров';
							|en = 'Pick goods'; fa = 'انتخاب کالاها';
							|it = 'Selezione delle merci';
							|pl = 'Wybór towarów';
							|tr = 'Ürünlerin seçimi'");
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList,,, QuestionTitle);
		
	ElsIf ValueIsFilled(SelectionData_1.TheShipmentDateOfAllLinesIsASingleDate)
				And ValueIsFilled(SelectionData_1.MaximumShipmentDate)
				And SelectionData_1.MaximumShipmentDate <> SelectionData_1.TheShipmentDateOfAllLinesIsASingleDate Then
				
		ShowQuestionAboutShippingByOneDate(
			CallbackDescription,
			SelectionData_1.TheShipmentDateOfAllLinesIsASingleDate,
			SelectionData_1.MaximumShipmentDate,
			Max(SelectionData_1.TheShipmentDateOfAllLinesIsASingleDate, SelectionData_1.MaximumShipmentDate),
			NStr("vi = 'Chọn hàng hóa';
				|ru = 'Подбор товаров';
				|en = 'Pick goods'; fa = 'انتخاب کالاها';
				|it = 'Selezione delle merci';
				|pl = 'Wybór towarów';
				|tr = 'Ürünlerin seçimi'"));
		
	Else
		
		RunCallback(CallbackDescription);
		
	EndIf;
	
EndProcedure

// Shows a question about whether to remove the "Ship by one date" flag after executing the Ship command in the security status form.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  DateSettingParameters - Structure - structure with fields:
//   * TheShipmentDateOfAllLinesIsASingleDate - Date - the date of shipment in the order header.
//   * DateWhenTheNewLinesWereShipped - Date - the shipment date that is set from the security status for the order lines that are being changed.
//  ActionCode - String  - the string "ACTION_LOAD".
//  NameOfNotificationProcedure - String - notification procedure in the order form to which control will be transferred after the response.
//
Procedure ShowIssueUncheckShipByOneDateInStateOfProvision(Form, DateSettingParameters, ActionCode, NameOfNotificationProcedure) Export
	
	Text = NStr("vi = 'Ngày giao hàng của các mặt hàng đã chọn %1, ngày giao hàng trong chứng từ %2.
		|Có thể giao tất cả vào một ngày %3, có thể xóa cờ giao một ngày trong chứng từ.';
		|ru = 'Дата отгрузки для выбранных позиций %1, дата отгрузки в документе %2.
		|Можно отгрузить все одной датой %3, можно снять флаг отгрузки одной датой в документе.';
		|en = 'The shipment date for the selected items is %1. The shipment date in the document is %2.
		|All items can be shipped at once on %3, or you can clear the same date shipment check box in the document.'; fa = 'The shipment date for the selected items is %1. The shipment date in the document is %2.
		|All items can be shipped at once on %3, or you can clear the same date shipment check box in the document.';
		|it = 'La data di spedizione per le posizioni selezionate è %1, la data di spedizione nel documento è %2.
		|È possibile fare un''unica spedizione in data %3, oppure rimuovere il flag di spedizione in un''unica data nel documento.';
		|pl = 'Data wysyłki dla wybranych pozycji %1, data wysyłki w dokumencie %2.
		|Można wysłać wszystką w jednym dniu %3, można odznaczać pole wyboru wysyłki w jednym dniu w dokumencie.';
		|tr = 'Seçili konumlar %1 için sevkiyat tarihi, %2 belgesindeki sevkiyat tarihi.
		|Her şey %3 aynı tarihte sevk edilebilinir, belgede aynı tarihte sevkiyat bayrağını kaldırılabilinir.'");
	ButtonText = NStr("vi = 'Xóa cờ giao trong một ngày.';
						|ru = 'Снять флаг отгрузки одной датой.';
						|en = 'Clear the same date shipment check box.'; fa = 'Clear the same date shipment check box.';
						|it = 'Rimuovere il flag di spedizione in un''unica data.';
						|pl = 'Odznacz pole wyboru wysyłki w jednym dniu.';
						|tr = 'Aynı tarihte sevkiyat bayrağını kaldır.'");
	
	CallbackDescription = New CallbackDescription(NameOfNotificationProcedure, Form, ActionCode);
	
	If DateSettingParameters.TheShipmentDateOfAllLinesIsASingleDate <> Undefined
			And DateSettingParameters.TheShipmentDateOfAllLinesIsASingleDate <> DateSettingParameters.DateWhenTheNewLinesWereShipped Then
		
		ShowQuestionAboutShippingByOneDate(
			CallbackDescription,
			DateSettingParameters.TheShipmentDateOfAllLinesIsASingleDate,
			DateSettingParameters.DateWhenTheNewLinesWereShipped,
			Max(DateSettingParameters.TheShipmentDateOfAllLinesIsASingleDate, DateSettingParameters.DateWhenTheNewLinesWereShipped),
			NStr("vi = 'Trạng thái đảm bảo';
				|ru = 'Состояние обеспечения';
				|en = 'Supply forecast'; fa = 'پیش‌بینی تأمین';
				|it = 'Stato di approvvigionamento';
				|pl = 'Status zaopatrzenia';
				|tr = 'Tedarik durumu'"),
			Text,
			ButtonText);
			
	Else
		
		RunCallback(CallbackDescription);
		
	EndIf;
	
EndProcedure

// Shows a question about whether to remove the "Ship on one date" flag when setting the security action in the order list.
//
// Parameters:
//  Orders - Array of AnyRef - an array of orders for which the action is being performed.
//  ActionCode - String - the symbol of the team, "DEJSTVITELBNOSTI" or "DEYSTVITEL"
//                         or "TASTIERARIO" or "TASTIERISTA".
//  DateParameters_ - Structure - Providing a document for the server call.Perform the actions of the order list.
//  Form - ClientApplicationForm - order list form.
//  CallbackDescription - CallbackDescription - Description Of The Notification After The Question
//
Procedure ShowQuestionUncheckShipByOneDateForListOfOrders(Orders, ActionCode, DateParameters_, Form, CallbackDescription = Undefined) Export
	
	Parameters = New Structure();
	Parameters.Insert("Orders", Orders);
	Parameters.Insert("ActionCode", ActionCode);
	Parameters.Insert("Form", Form);
	Parameters.Insert("EmbeddingParameters", Undefined);
	If CallbackDescription = Undefined Then
		CallbackDescription = New CallbackDescription("AfterQuestionInOrderList", ThisObject, Parameters); 
	EndIf;
	
	ButtonsList = New ValueList();
	QuestionTextTemplate = NStr("vi = 'Do kết quả điền chứng từ, ngày giao hàng trong các dòng sẽ khác nhau.
		|Có thể giao toàn bộ hàng trong một ngày %1, có thể giao từng phần.';
		|ru = 'В результате заполнения документов даты отгрузки в строках будут отличаться.
		|Можно отгрузить все одной датой %1, можно отгружать частями.';
		|en = 'Document population will result in different shipping dates in the lines.
		|All items can be shipped at once on %1, or in installments.'; fa = 'Document population will result in different shipping dates in the lines.
		|All items can be shipped at once on %1, or in installments.';
		|it = 'A seguito della compilazione dei documenti le date di spedizione nelle righe saranno diverse.
		|Si possono spedire nella stessa data %1, o in parti.';
		|pl = 'W rezultacie wypełnienia dokumentów daty wysyłki w wierszach będą różnić się.
		|Można wysłać wszystko w jednym dniu %1, można wysyłać częściami.';
		|tr = 'Belgelerin doldurulması sonucunda satırlardaki sevkiyat tarihleri ​​farklılık gösterecektir.
		|Her şey %1 tarihinde veya parça parça sevk edilebilinir.'");
	
	OneDateAsString = Format(DateParameters_.DateWhenTheNewLinesWereShipped, "DLF=D");
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTextTemplate, OneDateAsString);
	
	ButtonsList = New ValueList();
	ButtonTemplate = NStr("vi = 'Giao hàng trong một ngày (%1)';
							|ru = 'Отгрузить одной датой (%1)';
							|en = 'Same-date shipment (%1)'; fa = 'Same-date shipment (%1)';
							|it = 'Spedisci una data (%1)';
							|pl = 'Wyślij w jednym dniu (%1)';
							|tr = 'Aynı tarihte sevk et (%1)'");
	ButtonText = StringFunctionsClientServer.SubstituteParametersToString(ButtonTemplate, OneDateAsString);
	ButtonsList.Add("DialogReturnCode_No", ButtonText);
	ButtonsList.Add("DialogReturnCode_Yes", NStr("vi = 'Giao hàng từng phần';
												|ru = 'Отгружать частями';
												|en = 'Ship in installments'; fa = 'Ship in installments';
												|it = 'Spedire in parti';
												|pl = 'Wysyłaj częściowo';
												|tr = 'Parçalar halinde sevk et'"));
	
	QuestionTitle = NStr("vi = 'Điền thao tác trong danh sách đơn hàng';
						|ru = 'Заполнение действия в списке заказов';
						|en = 'Action population in the order list'; fa = 'Action population in the order list';
						|it = 'Compilazione dell''azione nell''elenco degli ordini';
						|pl = 'Wypełnienie działania na liście zamówień';
						|tr = 'Sipariş listesindeki bir işlemi doldurma'");
	
	FormParameters = TMCommonUseClient.FormParametersQuestionYesNoCancel();
	FormParameters.QueryText = QueryText;
	FormParameters.ButtonsList = ButtonsList;
	FormParameters.QuestionTitle = QuestionTitle;
	FormParameters.ShowCloseButton = True;
	DescriptionOfNotificationIntermediate = New CallbackDescription("NotificationProcessingIsIntermediate",
		ThisObject, CallbackDescription);
	OpenForm("CommonForm.QuestionYesNoCancel", FormParameters, Form, , , , DescriptionOfNotificationIntermediate);

EndProcedure

// Checks that when performing the security actions on the order lines, you need to ask a question about the shipment by a single date,
// whole or fractional packages.
//
// Parameters:
//  ResultOfActions - See SupplyInDocumentsServerCall.PerformActionInOrderList
//
// Returns:
//  Boolean - True if the question is needed, False otherwise.
//
Function ResultOfPerformingActionsNeedQuestion(ResultOfActions) Export
	
	Return TypeOf(ResultOfActions) = Type("Structure") And ResultOfActions.Property("NeedQuestion");
	
EndFunction

// The handler for selecting the security option in the order line.
//
// Parameters:
//  Form - ClientApplicationForm - order list form.
//  CurrentData - FormDataCollectionItem - the line in which the security option was selected.
//  ValueSelected - Structure - structure of the choice of the security option.
//
Procedure SupplyOptionChoiceProcessing(Form, CurrentData, ValueSelected) Export
	
	InternalParameters = Form.AvailableRemainingEmbeddingOptions.InternalParameters;
	InternalParameters.SupplyOptionBeforeChange = CurrentData.SupplyOption;
	InternalParameters.SecurityOptionSelectedValue = ValueSelected;
	
EndProcedure

// Handler when changing the collateral option in the order line.
//
// Parameters:
//  Form - ClientApplicationForm - order list form.
//  FormParameters - See ProvisionInDocumentsServer.SoftwareSelectionParameters
//  NameOfWarehouseAndBatchSelectionProcedure - String - the name of the procedure responsible in the order form for processing the closing of the warehouse and series selection form
//  AskQuestionAboutShipmentByOneDate - Boolean - True, If you need to ask a question about shipping by one date
//  ProcedureNameAfterQuestion - String - the name of the procedure from the order form module to be called after processing is complete 
//
Procedure SupplyOptionOnChange(
			Form,
			FormParameters,
			NameOfWarehouseAndBatchSelectionProcedure,
			AskQuestionAboutShipmentByOneDate,
			ProcedureNameAfterQuestion) Export
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	InternalParameters = EmbeddingParameters.InternalParameters;
	If EmbeddingParameters.FormTableName <> Undefined Then
		CurrentData = Form.Items[EmbeddingParameters.FormTableName].CurrentData;
	Else
		CurrentData = Form.Object;
	EndIf;
	
	If InternalParameters.SecurityOptionSelectedValue = Undefined Then
		Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
		Value.SupplyOption = CurrentData.SupplyOption;
		InternalParameters.SecurityOptionSelectedValue = Value;
	Else
		If InternalParameters.SecurityOptionSelectedValue.OpenWarehouseAndSeriesSelectionForm
				Or InternalParameters.SecurityOptionSelectedValue.OpenLineSplittingForm Then
			CurrentData.SupplyOption = InternalParameters.SupplyOptionBeforeChange;
		EndIf;
	EndIf;
	SecurityOptionSelectedValue = InternalParameters.SecurityOptionSelectedValue;
	
	If SecurityOptionSelectedValue.OpenWarehouseAndSeriesSelectionForm Then
		
		If FormParameters <> Undefined Then
			
			FormParameters.SelectSeries = True;
			FormParameters.SecurityOptionForTheDocument = SecurityOptionSelectedValue.SupplyOption;
			
			OpenForm(
				"DataProcessor.QuantityAndBatchRequest.Form",
				FormParameters,
				Form,
				,
				,
				,
				New CallbackDescription(NameOfWarehouseAndBatchSelectionProcedure, Form, FormParameters));
			
		EndIf;
		
	ElsIf SecurityOptionSelectedValue.OpenLineSplittingForm Then
		
		ProcessingParameters = New Structure();
		If AskQuestionAboutShipmentByOneDate Then
			AdditionalParameters = New Structure("Form,ProcedureNameAfterQuestion", Form, ProcedureNameAfterQuestion);
			NotificationAfterProcessing = New CallbackDescription(
				"ProcessPartitionOfCollateralOption",
				ThisObject,
				AdditionalParameters);
		Else
			NotificationAfterProcessing = New CallbackDescription(ProcedureNameAfterQuestion, Form);
		EndIf;
		ProcessingParameters.Insert("NotificationAfterSplitting", NotificationAfterProcessing);
		ProcessingParameters.Insert("Form", Form);
		EnterQuantityToSplit(ProcessingParameters);
		
	ElsIf AskQuestionAboutShipmentByOneDate Then
		
		ShowQuestionUncheckShipByOneDateWhenSpecifyingCollateralOption(
			Form,
			SecurityOptionSelectedValue,
			ProcedureNameAfterQuestion);
			
	Else
		
		NotificationAfterProcessing = New CallbackDescription(ProcedureNameAfterQuestion, Form);
		RunCallback(NotificationAfterProcessing);
		
	EndIf;
	
EndProcedure

// Returns a flag indicating whether the warehouse and batch selection form should be opened in the order.
// Parameters:
//  Form - ClientApplicationForm
// Returns:
//  Boolean - True if you need to open the warehouse and batch selection form.
Function OpenWarehouseAndSeriesSelectionForm(Form) Export
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	InternalParameters = EmbeddingParameters.InternalParameters;
	Result = InternalParameters.SecurityOptionSelectedValue <> Undefined
		And InternalParameters.SecurityOptionSelectedValue.OpenWarehouseAndSeriesSelectionForm;
	
	If Result Then
		If EmbeddingParameters.FormTableName = Undefined Then
			CurrentData = Form.Object;
		Else
			CurrentData = Form.Items[EmbeddingParameters.FormTableName].CurrentData;
		EndIf;
		CurrentData.SupplyOption = InternalParameters.SupplyOptionBeforeChange;
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether the "Available" column in the order form needs to be updated based on the results of
// the action to check whether the "Available" column needs to be updated in the action structure.
//
// Parameters:
//  StructureOfActions - Structure - the structure of the completed actions.
//
// Returns:
//  Boolean - True, if you need to update the column is available.
//
Function YouNeedToUpdateAvailableColumn(StructureOfActions) Export
	
	Result = StructureOfActions.Property("CheckNeedToUpdateColumnIsAvailable")
		And StructureOfActions.CheckNeedToUpdateColumnIsAvailable.UpdateColumnAvailable;
		
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Serving forms of document lists

// If the background inventory allocation task is not running, then it starts it.
Procedure CheckToRunBackgroundInventoryAllocationJob() Export
	
	SupplyInDocumentsServerCall.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

// Checks the completion of the inventory allocation task for orders in the order list.
//
// Parameters:
//  Form - ClientApplicationForm - order list form.
//  List - FormTable - list of orders on the form.
//
Procedure CheckWhetherInventoryAllocationTaskIsCompletedForOrders(Form, List) Export
	
	ReferencesArrray = Form.OrdersToCheckTheInventoryAllocationTask.UnloadValues();
	If SupplyInDocumentsServerCall.ThereAreTasksForOrders(ReferencesArrray) Then
		Form.InventoryAllocationTaskValidationInterval = Form.InventoryAllocationTaskValidationInterval + 1;
		Form.AttachIdleHandler("Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders",
			Form.InventoryAllocationTaskValidationInterval, True);
	Else
		
		List.Refresh();
		
	EndIf;
	
EndProcedure

// Handler for the list change event.
//
// Parameters:
//  Form - ClientApplicationForm - order list form.
//  FullNamesOfDocuments - String - full names of documents displayed in a comma-separated list.
//
Procedure ListOnChange(Form, FullNamesOfDocuments) Export
	
	ReferencesArrray = SupplyInDocumentsServerCall.TasksForOrdersByType(FullNamesOfDocuments);
	If ReferencesArrray.Count() > 0 Then
		
		Form.OrdersToCheckTheInventoryAllocationTask.LoadValues(ReferencesArrray);
		Form.InventoryAllocationTaskValidationInterval = 1;
		Form.AttachIdleHandler("Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders",
			Form.InventoryAllocationTaskValidationInterval, True);
			
	EndIf;
	
EndProcedure

// Reports the results of performing the security actions in the list of orders.
//
// Parameters:
//  ResultOfActions - See SupplyInDocumentsServerCall.PerformActionInOrderList
//
Procedure ReportResultsOfActionsInOrderList(ResultOfActions) Export
	
	For Each Error In ResultOfActions.ErrorList Do
		
		Text = Error.Text;
		DataKey = Error.Ref;
		
		Field = "";
		If Error.Property("Field") Then
			Field = Error.Field;
		EndIf;
		
		DataPath = "";
		If Error.Property("DataPath") Then
			DataPath = Error.DataPath;
		EndIf;
		
		CommonClient.MessageToUser(Text, DataKey, Field, DataPath);
		
	EndDo;
	
	Text = StrTemplate(NStr("vi = 'Đã xử lý %1 chứng từ.';
							|ru = 'Обработано документов: %1.';
							|en = 'Processed documents: %1.'; fa = 'Processed documents: %1.';
							|it = 'Documenti elaborati: %1.';
							|pl = 'Przetworzono dokumentów: %1.';
							|tr = 'İşlenen belgeler: %1.'"), ResultOfActions.QuantityProcessed);
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), Undefined, Text);
	
EndProcedure

// Complements the structure of the result of the provision actions in the list, used if the list is processed
// in chunks.
//
// Parameters:
//  Receiver - See SupplyInDocumentsServerCall.PerformActionInOrderList
//  Source - See SupplyInDocumentsServerCall.PerformActionInOrderList
//
Procedure CompleteResultsOfActionsInOrderList(Receiver, Source) Export
	
	CommonClientServer.SupplementArray(Receiver.ErrorList, Source.ErrorList);
	Receiver.QuantityProcessed = Receiver.QuantityProcessed + Source.QuantityProcessed;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// OtherItems

// Processes the completion of the assignment adjustment.
//  Parameters:
//   ThisIsReservation - Boolean - True if it is necessary to open processing for reservation, false if it is necessary to withdraw the reserve.
//   Ref - DefinedType.ExpectedShipment - a link to the order in which the commands for separate reserving and removing the reserve are embedded.
//   CommandDetails - See SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment
Procedure OpenAssignmentAdjustmentFilling(ThisIsReservation, Ref, CommandDetails) Export
	
	CheckResult = SupplyInDocumentsServerCall.CheckingPossibilityOfOpeningFillingInAssignmentCorrection(
		ThisIsReservation, Ref);
	
	If ThisIsReservation Then
		
		If CheckResult.ThereAreGoodsToSeparateProvision Then
			GenerationByReferenceTMClient.OpenBackupWizard(CommandDetails);
		ElsIf CheckResult.ThereAreGoodsToThirdPartyStandAloneCollateral Then
			SupplyClient.ReportAbsenceOfGoodsForSeparateSecurityForCurOrder(True);
		Else
			SupplyClient.ReportAbsenceOfGoodsForSeparateProvision();
		EndIf;
	
	Else
		
		If CheckResult.ThereAreGoodsToWithdrawReserve Then
			GenerationByReferenceTMClient.OpenReserveWithdrawalWizard(CommandDetails);
		ElsIf CheckResult.HaveAccessToThirdPartyReserveWithdrawals Then
			SupplyClient.ReportAbsenceOfGoodsForSeparateSecurityForCurOrder(False);
		Else
			SupplyClient.ReportAbsenceOfGoodsForWithdrawalOfReserve();
		EndIf;
	
	EndIf;

EndProcedure

#EndRegion

#Region Internal

Procedure FillInDatesInSecondStepOfDemandFulfillment(TableRow) Export
	
	TableRow.ShipmentDate = '00010101';
	TableRow.BoundaryOfCoveredPeriod = '00010101';
	If TableRow.DemandConversionOption = 1
			And TableRow.GenerateOrdersOnSchedule Then
		TableRow.ShipmentDate = TableRow.DeliveryDateOnSchedule;
		TableRow.BoundaryOfCoveredPeriod = TableRow.CoveredPeriodBoundaryOnSchedule;
	ElsIf TableRow.DemandConversionOption = 2 Then
		TableRow.ShipmentDate = TableRow.DeliveryDateOnSchedule;
		TableRow.BoundaryOfCoveredPeriod = TableRow.CoveredPeriodBoundaryOnSchedule;
	ElsIf TableRow.DemandConversionOption = 0 Then
		TableRow.DemandConversionOption = 0;
		TableRow.ShipmentDate = TableRow.DeliveryDateByReorderPoint;
		// Before the order date, meet the needs until the date of the next delivery on schedule.
		TableRow.BoundaryOfCoveredPeriod = TableRow.CoveredPeriodBoundaryByReorderPoint;
	EndIf;
	
EndProcedure

Procedure ProcessPartitionOfCollateralOption(SecurityOptionSelectedValue, AdditionalParameters) Export
	
	ShowQuestionUncheckShipByOneDateWhenSpecifyingCollateralOption(
		AdditionalParameters.Form,
		SecurityOptionSelectedValue,
		AdditionalParameters.ProcedureNameAfterQuestion);
	
EndProcedure

Procedure EnterQuantityToSplit(ProcessingParameters) Export
	
	Notification = New CallbackDescription("EnterNumberToSplitAfterEntering", ThisObject, ProcessingParameters);
	EmbeddingParameters = ProcessingParameters.Form.AvailableRemainingEmbeddingOptions;
	SecurityOptionSelectedValue = EmbeddingParameters.InternalParameters.SecurityOptionSelectedValue;
	If SecurityOptionSelectedValue.SupplyOption
			= PredefinedValue("Enum.SupplyOptions.Ship") Then 
		InputHeader = NStr("vi = 'Nhập số lượng để giao hàng';
							|ru = 'Ввод количества для отгрузки';
							|en = 'Enter the quantity to ship'; fa = 'Enter the quantity to ship';
							|it = 'Ввод количества для отгрузки';
							|pl = 'Enter the quantity to ship';
							|tr = 'Sevkiyat için miktar girişi'");
	Else
		InputHeader = NStr("vi = 'Nhập số lượng để dự phòng';
							|ru = 'Ввод количества для резервирования';
							|en = 'Enter the quantity to reserve'; fa = 'Enter the quantity to reserve';
							|it = 'Ввод количества для резервирования';
							|pl = 'Enter the quantity to reserve';
							|tr = 'Rezerve için miktar girişi'");
	EndIf;
	ShowInputNumber(Notification,
		SecurityOptionSelectedValue.AvailableQuantityWhenSplittingLine,
		InputHeader, 15, 3);
	
EndProcedure

Procedure EnterNumberToSplitAfterEntering(Count, ProcessingParameters) Export
	
	If Count = Undefined Then
		Return;
	EndIf;
	
	EmbeddingParameters = ProcessingParameters.Form.AvailableRemainingEmbeddingOptions;
	SecurityOptionSelectedValue = EmbeddingParameters.InternalParameters.SecurityOptionSelectedValue; // Structure
	AvailableQuantity = SecurityOptionSelectedValue.AvailableQuantityWhenSplittingLine;
	CommonCount = SecurityOptionSelectedValue.TotalNumberWhenSplittingLine;
	
	MessageText = Undefined;
	If Count = 0 Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không thể bằng 0.';
							|ru = 'Количество в новой строке не может быть равно нулю.';
							|en = 'Quantity in a new line should not be equal to zero.'; fa = 'Quantity in a new line should not be equal to zero.';
							|it = 'La quantità nella nuova riga non può essere pari a zero.';
							|pl = 'Ilość w nowym wierszu nie może być równa zeru.';
							|tr = 'Yeni satırdaki sayı sıfıra eşit olamaz.'");
	ElsIf Count < 0 Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không thể âm.';
							|ru = 'Количество в новой строке не может быть отрицательным.';
							|en = 'Quantity in a new line should not be negative.'; fa = 'Quantity in a new line should not be negative.';
							|it = 'La quantità nella nuova riga non può essere negativa.';
							|pl = 'Ilość w nowym wierszu nie może być ujemna.';
							|tr = 'Yeni satırdaki sayı negatif olamaz.'");
	ElsIf Count > CommonCount Then
		MessageText = NStr("vi = 'Số lượng trong dòng mới không thể lớn hơn số lượng trong dòng hiện tại.';
							|ru = 'Количество в новой строке не может быть больше количества в текущей строке.';
							|en = 'Quantity in a new line cannot be greater than the quantity in the current line.'; fa = 'Quantity in a new line cannot be greater than the quantity in the current line.';
							|it = 'Количество в новой строке не может быть больше количества в текущей строке.';
							|pl = 'Quantity in a new line cannot be greater than the quantity in the current line.';
							|tr = 'Yeni satırdaki miktar, mevcut satırdaki miktardan fazla olamaz.'");
	ElsIf Count > AvailableQuantity + Count
				* SecurityOptionSelectedValue.AcceptableDeviationOnChoiceSupplyOption / 100 Then
		If SecurityOptionSelectedValue.SupplyOption
				= PredefinedValue("Enum.SupplyOptions.Ship") Then
			MessageText = NStr("ru = 'Количество в новой строке не может быть больше доступного для отгрузки количества в текущей строке.';
								|vi = 'Quantity in a new line cannot be greater than the quantity available for shipment in the current line.';
								|en = 'Quantity in a new line cannot be greater than the quantity available for shipment in the current line.'; fa = 'Quantity in a new line cannot be greater than the quantity available for shipment in the current line.';
								|it = 'Quantity in a new line cannot be greater than the quantity available for shipment in the current line.';
								|pl = 'Quantity in a new line cannot be greater than the quantity available for shipment in the current line.';
								|tr = 'Yeni satırdaki miktar, geçerli satırdaki sevkiyat için uygun miktardan fazla olamaz.'");
		Else
			MessageText = NStr("ru = 'Количество в новой строке не может быть больше доступного для резервирования количества в текущей строке.';
								|vi = 'Quantity in a new line cannot be greater than the quantity available for reservation in the current line.';
								|en = 'Quantity in a new line cannot be greater than the quantity available for reservation in the current line.'; fa = 'Quantity in a new line cannot be greater than the quantity available for reservation in the current line.';
								|it = 'Quantity in a new line cannot be greater than the quantity available for reservation in the current line.';
								|pl = 'Quantity in a new line cannot be greater than the quantity available for reservation in the current line.';
								|tr = 'Yeni satırdaki miktar, geçerli satırdaki rezervasyon için uygun miktardan fazla olamaz.'");
		EndIf;
	EndIf;
	
	If ValueIsFilled(MessageText) Then
		Notification = New CallbackDescription("EnterQuantityToSplit", ThisObject, ProcessingParameters);
		ShowMessageBox(Notification, MessageText);
	Else
		
		SecurityOptionSelectedValue.OpenLineSplittingForm = False;
		If Count <> CommonCount Then
			SecurityOptionSelectedValue.SplitRow = True;
			SecurityOptionSelectedValue.Available = Count;
		EndIf;
		RunCallback(ProcessingParameters.NotificationAfterSplitting, SecurityOptionSelectedValue);
		
	EndIf;
	
EndProcedure

Procedure NotificationProcessingIsIntermediate(Response, CallbackDescription) Export
	
	If Response <> Undefined Then
		RunCallback(CallbackDescription, Response);
	EndIf;
	
EndProcedure

Procedure ProcessingAlertAfterSelectingSecurity(Response, CallbackDescription) Export
	
	If Response = Undefined Then
		InternalParameters = CallbackDescription.Module.AvailableRemainingEmbeddingOptions.InternalParameters;
		If InternalParameters.Property("SupplyOptionBeforeChange") Then
			InternalParameters.SecurityOptionSelectedValue.SupplyOption = InternalParameters.SupplyOptionBeforeChange;
			CallbackDescription.Module.Modified = False;
		EndIf;
	EndIf;
	RunCallback(CallbackDescription, Response);
	
EndProcedure

Function FieldStructureCheckIfColumnUpdatesAreAvailable() Export
	
	FieldsStructure = New Structure();
	FieldsStructure.Insert("Products");
	FieldsStructure.Insert("Characteristic");
	FieldsStructure.Insert("SupplyOption");
	Return FieldsStructure;
	
EndFunction

Procedure AfterQuestionInOrderList(Response, Parameters) Export
	
	ProcedureParameters = CommonClient.CopyRecursive(Parameters);
	Form = Parameters.Form;
	ProcedureParameters.Delete("Form");

	FillParameters = New Structure();
	FillParameters.Insert("UncheckShipByOneDateFlag",    Response = "DialogReturnCode_Yes");
	FillParameters.Insert("FillShippingDateWithSingleDate", Response = "DialogReturnCode_No");
	ProcedureParameters.Insert("FillParameters", FillParameters);
	ResultOfActions = SupplyInDocumentsServerCall.PerformActionForOrdersAfterQuestionByBackgroundTask(
		ProcedureParameters, Form.UUID);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	AdditionalParameters = New Structure("Form,Orders",
		Form, ProcedureParameters.Orders);
	TimeConsumingOperationsClient.WaitCompletion(ResultOfActions,
		New CallbackDescription("AfterQuestionInOrderListCompletion", ThisObject, AdditionalParameters),
		IdleParameters);
	
EndProcedure

Procedure AfterQuestionInOrderListCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		
		Return;
		
	ElsIf Result.Status = "Error" Then
		
		ShowMessageBox(, Result.BriefErrorDescription);
		
	Else
		
		Form = AdditionalParameters.Form;
		ResultOfActions = GetFromTempStorage(Result.ResultAddress);
		Form.OrdersToCheckTheInventoryAllocationTask.LoadValues(AdditionalParameters.Orders);
		Form.AttachIdleHandler("Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders", 1, True);
		ReportResultsOfActionsInOrderList(ResultOfActions);
		
	EndIf;
	
EndProcedure

Function ReserveFormParameters() Export
	
	Parameters = New Structure();
	Parameters.Insert("Products");
	Parameters.Insert("Characteristic");
	Parameters.Insert("Warehouse");
	Parameters.Insert("Purpose");
	Parameters.Insert("ControlledLotReference");
	Parameters.Insert("ShippingOrders");
	Parameters.Insert("Package");
	Return Parameters;
	
EndFunction

// Returns:
//  Structure - structure with fields:
//   * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure -
//   * Products - CatalogRef.Products -
//   * Characteristic - CatalogRef.ItemsCharacteristics -
//   * Warehouse - CatalogRef.Warehouses -
//   * Purpose - CatalogRef.Assignments -
//   * ShipmentOrder - DefinedType.ExpectedShipment -
Function ParametersOfQuantityInputFormReserveFromOtherOrders() Export
	
	FormParameters = New Structure();
	FormParameters.Insert("UnitOfMeasure");
	FormParameters.Insert("Products");
	FormParameters.Insert("Characteristic");
	FormParameters.Insert("Warehouse");
	FormParameters.Insert("Purpose");
	FormParameters.Insert("ShipmentOrder");
	Return FormParameters;

EndFunction

#EndRegion

#Region Private

// Shows the question about whether to remove the "Ship on one date" flag when setting the security action in
// the order line if the form for specifying warehouses and series does not open.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  SecurityOptionSelectedValue - Structure - the result of processing the action selection in the order line.
//  NameOfNotificationProcedure - String - notification procedure in the order form to which control will be transferred after the response.
//
Procedure ShowQuestionUncheckShipByOneDateWhenSpecifyingCollateralOption(Form, SecurityOptionSelectedValue, NameOfNotificationProcedure)
	
	CallbackDescription = New CallbackDescription(NameOfNotificationProcedure, Form, Undefined);
	
	AskQuestion_ = False;
	SupplyOption = SecurityOptionSelectedValue.SupplyOption;
	If SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
			And SupplyOption <> Form.AvailableRemainingEmbeddingOptions.InternalParameters.SupplyOptionBeforeChange Then
			
		AvailableRemainingDocumentParameters = AvailableRemainingDocumentParameters(Form);
		TheShipmentDateOfAllLinesIsASingleDate = SupplyInDocumentsServerCall.TheShipmentDateOfAllLinesIsASingleDate(
			AvailableRemainingDocumentParameters);
		DateWhenTheNewLinesWereShipped = BegOfDay(CommonClient.SessionDate());
		
		PaddingForAllRows = ProvisionInDocumentsClientServer.CollectionOnForm(Form,
			Form.AvailableRemainingEmbeddingOptions).Count() = 1
				And Not SecurityOptionSelectedValue.SplitRow;
		AskQuestion_ = TheShipmentDateOfAllLinesIsASingleDate <> Undefined
				And TheShipmentDateOfAllLinesIsASingleDate < DateWhenTheNewLinesWereShipped
				And AvailableRemainingDocumentParameters.EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList
					<> "UNDEFINED";
				
	EndIf;
	
	If AskQuestion_ And Not PaddingForAllRows Then
		
		QuestionTextTemplate = NStr("vi = 'Ngày giao hàng của dòng được chọn %1, ngày giao hàng của các dòng còn lại %2.
				|Có thể giao toàn bộ vào một ngày %3, có thể giao hàng từng phần.';
				|ru = 'Дата отгрузки выбранной строки %1, дата отгрузки остальных строк %2.
				|Можно отгрузить все одной датой %3, можно отгружать частями.';
				|en = 'Shipment date of the selected line is %1, shipment date of other lines is %2.
				|All items can be shipped at once on %3 or in installments.'; fa = 'Shipment date of the selected line is %1, shipment date of other lines is %2.
				|All items can be shipped at once on %3 or in installments.';
				|it = 'Дата отгрузки выбранной строки %1, дата отгрузки остальных строк %2.
				|Можно отгрузить все одной датой %3, можно отгружать частями.';
				|pl = 'Shipment date of the selected line is %1, shipment date of other lines is %2.
				|All items can be shipped at once on %3 or in installments.';
				|tr = 'Seçilen %1 satırının sevkiyat tarihi, kalan %2 satırlarının sevkiyat tarihi.
				|Hepsi aynı %3 tarihinde sevk edilebilir, parça parça sevk edilebilir.'");
		
		OldShipmentDateLine = Format(TheShipmentDateOfAllLinesIsASingleDate, "DLF=D");
		NewShipmentDateLine = Format(DateWhenTheNewLinesWereShipped, "DLF=D");
		OneDateAsString = NewShipmentDateLine;
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			QuestionTextTemplate,
			NewShipmentDateLine,
			?(TheShipmentDateOfAllLinesIsASingleDate = '00010101', NStr("vi = 'chưa chỉ định';
																		|ru = 'не указана';
																		|en = 'not specified'; fa = 'مشخص نشده';
																		|it = 'non specificato';
																		|pl = 'nie określona';
																		|tr = 'belirtilmedi'"),
				OldShipmentDateLine),
				OneDateAsString);
		
		ButtonsList = New ValueList();
		ButtonTemplate = NStr("vi = 'Giao hàng trong một ngày (%1)';
								|ru = 'Отгрузить одной датой (%1)';
								|en = 'Same-date shipment (%1)'; fa = 'Same-date shipment (%1)';
								|it = 'Spedisci una data (%1)';
								|pl = 'Wyślij w jednym dniu (%1)';
								|tr = 'Aynı tarihte sevk et (%1)'");
		ButtonText = StringFunctionsClientServer.SubstituteParametersToString(ButtonTemplate, OneDateAsString);
		ButtonsList.Add("DialogReturnCode_No", ButtonText);
		YesButtonTemplate = NStr("vi = 'Giao hàng từng phần';
								|ru = 'Отгружать частями';
								|en = 'Ship in installments'; fa = 'Ship in installments';
								|it = 'Spedire in parti';
								|pl = 'Wysyłaj częściowo';
								|tr = 'Parçalar halinde sevk et'");
		ButtonsList.Add("DialogReturnCode_Yes", YesButtonTemplate);
		
		FormParameters = TMCommonUseClient.FormParametersQuestionYesNoCancel();
		FormParameters.QueryText = QueryText;
		FormParameters.ButtonsList = ButtonsList;
		FormParameters.QuestionTitle = NStr("vi = 'Chọn hiệu lực';
											|ru = 'Выбор действия';
											|en = 'Select action'; fa = 'انتخاب اقدام';
											|it = 'Scelta dell''azione';
											|pl = 'Wybór czynności';
											|tr = 'Eylem seçimi'");
		FormParameters.ShowCloseButton = True;
		DescriptionOfNotificationIntermediate = New CallbackDescription("ProcessingAlertAfterSelectingSecurity",
			ThisObject, CallbackDescription);
		OpenForm("CommonForm.QuestionYesNoCancel", FormParameters, , , , , DescriptionOfNotificationIntermediate);
		
	ElsIf AskQuestion_ And PaddingForAllRows Then
		
		RunCallback(CallbackDescription, "DialogReturnCode_No");
		
	Else
		
		RunCallback(CallbackDescription);
		
	EndIf;
	
EndProcedure

Procedure ShowQuestionAboutShippingByOneDate(CallbackDescription, TheShipmentDateOfAllLinesIsASingleDate, DateWhenTheNewLinesWereShipped, OneDate, QuestionTitle, QuestionTextTemplate = Undefined, YesButtonTemplate = Undefined)
	
	If QuestionTextTemplate = Undefined Then
		
		QuestionTextTemplate = NStr("vi = 'Ngày giao hàng của các dòng đã chọn %1, ngày giao hàng của các dòng còn lại %2.
			|Có thể giao tất cả vào một ngày %3, có thể giao từng phần.';
			|ru = 'Дата отгрузки выбранных строк %1, дата отгрузки остальных строк %2.
			|Можно отгрузить все одной датой %3, можно отгружать частями.';
			|en = 'Shipment date of the selected lines %1, shipment date of other lines %2.
			|All items can be shipped at once on %3, or in installments.'; fa = 'Shipment date of the selected lines %1, shipment date of other lines %2.
			|All items can be shipped at once on %3, or in installments.';
			|it = 'Data di spedizione delle righe selezionate %1, data di spedizione delle altre righe %2.
			|È possibile spedire in unica data %3, è possibile spedire in parti.';
			|pl = 'Data wysłania wybranych wierszy %1, data wysłania pozostałych wierszy %2.
			|Można wysłać wszystkie w jednym dniu %3, można wysyłać częściami.';
			|tr = 'Seçilen satırların sevkiyat tarihi %1, kalan satırların sevkiyat tarihi %2''dir.
			|Her şey aynı tarihte %3 sevk edilebilinir, parça parça sevk edilebilinir.'");
	EndIf;
	
	OldShipmentDateLine = Format(TheShipmentDateOfAllLinesIsASingleDate, "DLF=D");
	NewShipmentDateLine = Format(DateWhenTheNewLinesWereShipped, "DLF=D");
	OneDateAsString = Format(OneDate, "DLF=D");
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionTextTemplate,
		NewShipmentDateLine,
		?(TheShipmentDateOfAllLinesIsASingleDate = '00010101', NStr("vi = 'chưa chỉ ra';
																	|ru = 'не указана';
																	|en = 'not specified'; fa = 'مشخص نشده';
																	|it = 'non specificato';
																	|pl = 'nie określona';
																	|tr = 'belirtilmedi'"),OldShipmentDateLine),
		OneDateAsString);
	
	ButtonsList = New ValueList();
	ButtonTemplate = NStr("vi = 'Giao hàng trong một ngày (%1)';
							|ru = 'Отгрузить одной датой (%1)';
							|en = 'Same-date shipment (%1)'; fa = 'Same-date shipment (%1)';
							|it = 'Spedisci una data (%1)';
							|pl = 'Wyślij w jednym dniu (%1)';
							|tr = 'Aynı tarihte sevk et (%1)'");
	ButtonText = StringFunctionsClientServer.SubstituteParametersToString(ButtonTemplate, OneDateAsString);
	ButtonsList.Add("DialogReturnCode_No", ButtonText);
	If YesButtonTemplate = Undefined Then
		YesButtonTemplate = NStr("vi = 'Giao hàng từng phần';
								|ru = 'Отгружать частями';
								|en = 'Ship in installments'; fa = 'Ship in installments';
								|it = 'Spedire in parti';
								|pl = 'Wysyłaj częściowo';
								|tr = 'Parçalar halinde sevk et'");
	EndIf;
	ButtonsList.Add("DialogReturnCode_Yes", YesButtonTemplate);
	
	FormParameters = TMCommonUseClient.FormParametersQuestionYesNoCancel();
	FormParameters.QueryText = QueryText;
	FormParameters.ButtonsList = ButtonsList;
	FormParameters.QuestionTitle = QuestionTitle;
	FormParameters.ShowCloseButton = True;
	DescriptionOfNotificationIntermediate = New CallbackDescription("NotificationProcessingIsIntermediate",
		ThisObject, CallbackDescription);
	OpenForm("CommonForm.QuestionYesNoCancel", FormParameters, , , , , DescriptionOfNotificationIntermediate);
	
EndProcedure

Procedure PerformActionInListOfOrdersOfDifferentTypes(ActionCode, List, Ref, Form) Export
	
	ClearMessages();
	AllOrders = TMCommonUseClient.CheckGetLinksHighlightedInList(List);
	
	ResultOfActions = SupplyInDocumentsServerCall.PerformActionInListOfOrdersOfDifferentTypes(
		ActionCode,
		AllOrders,
		Ref,
		Form.UUID);
	
	If ResultOfPerformingActionsNeedQuestion(ResultOfActions) Then
		
		ParametersStructure = New Structure("ResultOfActions,Form", ResultOfActions, Form);
		CallbackDescription = New CallbackDescription(
			"PerformActionInListOfOrdersOfDifferentTypesAfterQuestion",
			ThisObject,
			ParametersStructure);
		
		ButtonsList = New ValueList();
		QuestionTextTemplate = NStr("vi = 'Do kết quả điền chứng từ, ngày giao hàng trong các dòng sẽ khác nhau.
			|Có thể giao toàn bộ hàng trong một ngày %1, có thể giao từng phần.';
			|ru = 'В результате заполнения документов даты отгрузки в строках будут отличаться.
			|Можно отгрузить все одной датой %1, можно отгружать частями.';
			|en = 'Document population will result in different shipping dates in the lines.
			|All items can be shipped at once on %1, or in installments.'; fa = 'Document population will result in different shipping dates in the lines.
			|All items can be shipped at once on %1, or in installments.';
			|it = 'A seguito della compilazione dei documenti le date di spedizione nelle righe saranno diverse.
			|Si possono spedire nella stessa data %1, o in parti.';
			|pl = 'W rezultacie wypełnienia dokumentów daty wysyłki w wierszach będą różnić się.
			|Można wysłać wszystko w jednym dniu %1, można wysyłać częściami.';
			|tr = 'Belgelerin doldurulması sonucunda satırlardaki sevkiyat tarihleri ​​farklılık gösterecektir.
			|Her şey %1 tarihinde veya parça parça sevk edilebilinir.'");
		
		OneDateAsString = Format(ResultOfActions.DateWhenTheNewLinesWereShipped, "DLF=D");
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTextTemplate, OneDateAsString);
		
		ButtonsList = New ValueList();
		ButtonTemplate = NStr("vi = 'Giao hàng trong một ngày (%1)';
								|ru = 'Отгрузить одной датой (%1)';
								|en = 'Same-date shipment (%1)'; fa = 'Same-date shipment (%1)';
								|it = 'Spedisci una data (%1)';
								|pl = 'Wyślij w jednym dniu (%1)';
								|tr = 'Aynı tarihte sevk et (%1)'");
		ButtonText = StringFunctionsClientServer.SubstituteParametersToString(ButtonTemplate, OneDateAsString);
		ButtonsList.Add("DialogReturnCode_No", ButtonText);
		ButtonsList.Add("DialogReturnCode_Yes", NStr("vi = 'Giao hàng từng phần';
													|ru = 'Отгружать частями';
													|en = 'Ship in installments'; fa = 'Ship in installments';
													|it = 'Spedire in parti';
													|pl = 'Wysyłaj częściowo';
													|tr = 'Parçalar halinde sevk et'"));
		
		QuestionTitle = NStr("vi = 'Điền thao tác trong danh sách đơn hàng';
							|ru = 'Заполнение действия в списке заказов';
							|en = 'Action population in the order list'; fa = 'Action population in the order list';
							|it = 'Compilazione dell''azione nell''elenco degli ordini';
							|pl = 'Wypełnienie działania na liście zamówień';
							|tr = 'Sipariş listesindeki bir işlemi doldurma'");
		
		FormParameters = TMCommonUseClient.FormParametersQuestionYesNoCancel();
		FormParameters.QueryText = QueryText;
		FormParameters.ButtonsList = ButtonsList;
		FormParameters.QuestionTitle = QuestionTitle;
		FormParameters.ShowCloseButton = True;
		DescriptionOfNotificationIntermediate = New CallbackDescription("NotificationProcessingIsIntermediate",
			ThisObject, CallbackDescription);
		OpenForm("CommonForm.QuestionYesNoCancel", FormParameters, , , , , DescriptionOfNotificationIntermediate);
		
	Else
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		AdditionalParameters = New Structure("Orders", AllOrders);
		TimeConsumingOperationsClient.WaitCompletion(ResultOfActions,
			New CallbackDescription(
				"PerformActionInListOfOrdersOfDifferentTypesCompletion", Form, AdditionalParameters),
			IdleParameters);
	EndIf;

EndProcedure

Procedure PerformActionInListOfOrdersOfDifferentTypesAfterQuestion(Response, ParametersStructure) Export
	
	ResultOfActions = ParametersStructure.ResultOfActions;
	ResultOfActions.Insert("UncheckShipByOneDateFlag",    Response = "DialogReturnCode_Yes");
	ResultOfActions.Insert("FillShippingDateWithSingleDate", Response = "DialogReturnCode_No");
	
	Result = SupplyInDocumentsServerCall.PerformActionInListOfOrdersOfDifferentTypesAfterQuestion(
		ResultOfActions,
		ParametersStructure.Form.UUID);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ParametersStructure.Form);
	AllOrders = New Array();
	CommonClientServer.SupplementArray(AllOrders, ResultOfActions.ExecutionParameters[0].Orders);
	CommonClientServer.SupplementArray(AllOrders, ResultOfActions.ExecutionParameters[1].Orders);
	AdditionalParameters = New Structure("Orders", AllOrders);
	
	TimeConsumingOperationsClient.WaitCompletion(Result,
		New CallbackDescription(
			"PerformActionInListOfOrdersOfDifferentTypesCompletion", ParametersStructure.Form, AdditionalParameters),
		IdleParameters);
	
EndProcedure

#EndRegion
