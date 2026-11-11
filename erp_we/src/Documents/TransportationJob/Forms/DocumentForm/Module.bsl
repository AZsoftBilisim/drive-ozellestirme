// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
		
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		ReadOnly = True;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" mechanism
	PropertyManager.OnCreateAtServer(
		ThisObject,
		New Structure("ItemForPlacementName", "GroupAdditionalAttributes"));
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.TimeFrom);
	ElementsToFillIn.Add(Items.TimeTo);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	GoodsDelivery.SetAvailabilityOfDeliveryAddresses(Items);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	Items.EPDStateGroup.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	
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
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	FillGoodsForDelivery();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AdditionalProperties.Insert("GoodsToDeliver", GoodsToDeliver.Unload());
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	NotificationProcessingLocalization(EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Object.DeletionMark Then
		Notify("Write_TransportationJob");
	EndIf;
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.WorkplaceOfDeliveryOfficer.Form.ReferencesChoiceForm" Then
		SplitDeliveryPoint(ValueSelected);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillGoodsForDelivery();
	
	FillInServiceDetailsOfRoute();
	
	Items.FillOutOrdersForExpenditureOrders.Enabled = ValueIsFilled(Object.Ref);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_TransportationJob", Undefined, Object.Ref);
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Object.References.Count() > 0 Then
		
		If Warehouse <> Object.Warehouse Then
			
			ShowQueryBox(New CallbackDescription("WarehouseOnChangeCompletion", ThisObject),
				NStr("vi = 'Danh sách sẽ bị xóa. Tiếp tục?';
					|ru = 'Списки будут очищены. Продолжить?';
					|en = 'Lists will be cleared. Continue?'; fa = 'Lists will be cleared. Continue?';
					|it = 'Gli elenchi verranno cancellati. Continuare?';
					|pl = 'Listy zostaną oczyszczone. Kontynuować?';
					|tr = 'Listeler temizlenecek. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
			Return;
			
		Else
			Return;
		EndIf;
		
	Else
		
		Warehouse = Object.Warehouse;
		
	EndIf;
	
	WhenChangingWarehouseServer();
	
EndProcedure

&AtClient
Procedure Vehicle_OnChange(Item)
	
	VehicleWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If ValueIsFilled(Object.Ref)
		And Object.Operation = PredefinedValue("Enum.DeliveryKinds.FromWarehouse")
		And ThereAreAdvancedWarehouses
		And StatusWas <> Object.Status
		And StatusWas <> PredefinedValue("Enum.StatusesOfTransportationJobs.Closed")
		And StatusWas <> PredefinedValue("Enum.StatusesOfTransportationJobs.Sent")
		And (Object.Status = PredefinedValue("Enum.StatusesOfTransportationJobs.Closed")
			Or Object.Status = PredefinedValue("Enum.StatusesOfTransportationJobs.Sent")) Then
		
		Mode = New ValueList; // ValueList of DialogReturnCode
		Mode.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại';
											|ru = 'Перезаполнить';
											|en = 'Refill'; fa = 'پرکردن مجدد';
											|it = 'Ricompilare';
											|pl = 'Refill';
											|tr = 'Yeniden doldur'"));
		Mode.Add(DialogReturnCode.No, NStr("vi = 'Không điền lại';
											|ru = 'Не перезаполнять';
											|en = 'Do not refill'; fa = 'Do not refill';
											|it = 'Non ricompilare';
											|pl = 'Nie wypełniaj ponownie';
											|tr = 'Yeniden doldurma'"));
		Text = NStr("vi = 'Điền lại nhiệm vụ cho các phiếu xuất liên quan cho hàng hóa?';
					|ru = 'Перезаполнить задание по связанным расходным ордерам на товары?';
					|en = 'Refill the job by the linked goods issue notes?'; fa = 'Refill the job by the linked goods issue notes?';
					|it = 'Ricompilare il task secondo le note di carico di merci?';
					|pl = 'Uzupełnij pracę o powiązane zamówienia towarów na wiersze pozycji?';
					|tr = 'İlgili ambar çıkış fişi görevi yeniden doldurulsun mu?'");
		ShowQueryBox(New CallbackDescription("AfterQuestionOfReFillingOnOrders", ThisObject), Text, Mode);
		
	Else
		
		NotificationText1 = WhenChangingStatusAndOverfilling();
		NotifyAboutChanges_(NotificationText1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VehicleCubicMetresCapacityOnChange(Item)
	
	VehicleLoadCapacityCapacityWhenChanging();
	
EndProcedure

&AtClient
Procedure VehicleCarryingCapacityInTonsOnChange(Item)
	
	VehicleLoadCapacityCapacityWhenChanging();
	
EndProcedure

&AtClient
Procedure FlightDateTimePlanCWhenChanged(Item)
	
	For Each RouteString In Object.Route Do
		
		If RouteString.TimeFrom = '00010101'
			Or RouteString.TimeFrom < Object.PlanTripStartTime Then
			RouteString.TimeFrom = Object.PlanTripStartTime;
			RouteString.TimeFromWithoutDate = Date(1,1,1,Hour(RouteString.TimeFrom),Minute(RouteString.TimeFrom),0);
			If RouteString.TimeFrom > RouteString.TimeTo Then
				RouteString.TimeTo = RouteString.TimeFrom;
				RouteString.TimeFromWithoutDate = Date(1,1,1,Hour(RouteString.TimeTo),Minute(RouteString.TimeTo),0);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure JobIsPerformedByOnChange(Item)
	
	ConfigureByArtistType()
	
EndProcedure

&AtClient
Procedure CarrierOnChange(Item)
	
	CarrierWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DriverOnChange(Item)
	DriverWhenChangingOnServer();
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	CounterpartyWhenChangesAreMadeOnServer();
EndProcedure

&AtClient
Procedure DriverFullNameChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	ValueSelected.Property("Driver", Object.DriverFullName);
	ValueSelected.Property("CertificateSeries", Object.CertificateSeries);
	ValueSelected.Property("CertificateNumber", Object.CertificateNumber);
	
EndProcedure

&AtClient
Procedure DriverFullNameTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	DriverRecorded = False;	
	For Each DriverInformation In Item.ChoiceList Do
		If DriverInformation.Value.Driver = Text Then 
			DriverRecorded = True
		EndIf;
	EndDo;
	If Not DriverRecorded Then
		Object.CertificateNumber = "";
		Object.CertificateSeries = "";
		Object.DriverFullName   	  = Text;
	EndIf;
EndProcedure

&AtClient
Procedure VehicleRegPlateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	ValueSelected.Property("VehicleModel",							Object.VehicleModel);
	ValueSelected.Property("VehicleRegPlate",			Object.VehicleRegPlate);
	ValueSelected.Property("LicenseCardKind",					Object.LicenseCardKind);
	ValueSelected.Property("LicenseCardNumber",					Object.LicenseCardNumber);
	ValueSelected.Property("RegistrationNumberOfLicenseCard",	Object.RegistrationNumberOfLicenseCard);
	ValueSelected.Property("LicenseCardSeries",					Object.LicenseCardSeries);
	ValueSelected.Property("Trailer",									Object.Trailer);
	ValueSelected.Property("TrailerRegPlate",				Object.TrailerRegPlate);
	ValueSelected.Property("TransportationType",								Object.TransportationType);
	ValueSelected.Property("VehicleCubicMetresCapacity",	Object.VehicleCubicMetresCapacity);
	ValueSelected.Property("VehicleCarryingCapacityInTons",			Object.VehicleCarryingCapacityInTons);
	ValueSelected.Property("VehicleType",								Object.VehicleType);
EndProcedure

&AtClient
Procedure VehicleTypeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	ValueSelected.Property("VehicleCubicMetresCapacity",	Object.VehicleCubicMetresCapacity);
	ValueSelected.Property("VehicleCarryingCapacityInTons",			Object.VehicleCarryingCapacityInTons);
	ValueSelected.Property("VehicleType",								Object.VehicleType);
EndProcedure

&AtClient
Procedure VehicleTypeTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	VehicleRecorded = False;
	For Each VehicleInformation In Item.ChoiceList Do
		If VehicleInformation.Value.VehicleType = Text Then
			VehicleRecorded = True
		EndIf;
	EndDo;
	
	If Not VehicleRecorded Then
		
		Object.VehicleCarryingCapacityInTons = 0;
		Object.VehicleCubicMetresCapacity = 0;
		Object.VehicleType = Text;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationOfEPDClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationToIssueEPDClick(Item, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRoute

&AtClient
Procedure RouteBeforeDeleteRow(Item, Cancel)
	
	SelectedRows = Items.Route.SelectedRows;
	If SelectedRows.Count()>0 Then
		Modified = True;
		RouteBeforeDeletionOnServer(Items.Route.SelectedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure RouteBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure RouteDeliveredOnChange(Item)
	
	If Items.Route.CurrentData.Delivered Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("ConnectionKey",Items.Route.CurrentData.ConnectionKey);
		TheStructureOfTheSearch.Insert("Delivered", False);
		
		For Each Orders_Row In Object.References.FindRows(TheStructureOfTheSearch) Do
			Orders_Row.Delivered = True;
		EndDo;	
		
	Else
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("ConnectionKey",Items.Route.CurrentData.ConnectionKey);
		TheStructureOfTheSearch.Insert("Delivered", True);
		
		For Each Orders_Row In Object.References.FindRows(TheStructureOfTheSearch) Do
			Orders_Row.Delivered = False;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddressOnChange(Item)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("Address");
	CurrentData = Items.Route.CurrentData;
	
	GoodsDeliveryClient.WhenChangingAddressPresentation(
		Item,
		CurrentData[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		CurrentData[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues]);
	
EndProcedure

&AtClient
Procedure AddressOpening(Item, StandardProcessing)
	
	AddressOnChange(Item);
	
EndProcedure

&AtClient
Procedure AddressClearing(Item, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("Address");
	CurrentData = Items.Route.CurrentData;
	
	GoodsDeliveryClient.ClearAddressPresentation(
		CurrentData[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		CurrentData[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		CurrentData[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
		
EndProcedure

&AtClient
Procedure AddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("Address");
	CurrentData = Items.Route.CurrentData;
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		CurrentData,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure RouteTimeFromWhenChanged(Item)
	
	WhenChangingTimeFrom();
	SortRouteList();
	
EndProcedure

&AtClient
Procedure TheRouteDateFromWhenTheChange(Item)
	
	WhenChangingTimeFrom();
	SortRouteList();
	
EndProcedure

&AtClient
Procedure RouteTimeByWhenChanged(Item)
	
	WhenChangingDefaultTime();
	SortRouteList();
	
EndProcedure

&AtClient
Procedure RouteWeightOnChange(Item)
	
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	
EndProcedure

&AtClient
Procedure RouteVolumeM3OnChange(Item)
	
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	
EndProcedure

&AtClient
Procedure RouteSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	
	If Field.Name = "RouteRecipientsSenders" Then
		
		StandardProcessing = False;
		
		FormParameters = New Structure;
		FormParameters.Insert("TransportationJob", Object.Ref);
		FormParameters.Insert("Vehicle_", Object.Vehicle_);
		FormParameters.Insert("TaskWeight", Object.Route.Total("Weight"));
		FormParameters.Insert("TaskScope", Object.Route.Total("VolumeM3"));
		FormParameters.Insert("PlanTripStartTime", Object.PlanTripStartTime);
		FormParameters.Insert("DeliveryKind", Object.Operation);
		FormParameters.Insert("Address", CurrentData.Address);
		FormParameters.Insert("TimeFrom", CurrentData.TimeFrom);
		FormParameters.Insert("TimeTo", CurrentData.TimeTo);
		FormParameters.Insert("ReferenceAddress", PlaceOrdersInVault(CurrentData.ConnectionKey));
		FormParameters.Insert("Status", Object.Status);
		FormParameters.Insert("AddressOfGoodsForDelivery", PlaceGoodsInStorageForDelivery());
			
		CallbackDescription = New CallbackDescription("AfterEditingOrders",ThisObject);
		
		OpenForm("DataProcessor.WorkplaceOfDeliveryOfficer.Form.RoutePointReferences",
			FormParameters, ThisObject,,,, CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
	RouteSelectionLocalization(Item, RowSelected, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure RouteAdditionalInformationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("RouteAdditionalInformationStartChoiceCompletion", ThisObject);
	TitleOfEditingForm = NStr("vi = 'Thông tin bổ sung';
								|ru = 'Дополнительная информация';
								|en = 'Additional information'; fa = 'اطلاعات تکمیلی';
								|it = 'Informazione supplementare';
								|pl = 'Dodatkowa informacja';
								|tr = 'Ek bilgi'");
	
	CommonClient.ShowMultilineTextEditingForm(
		Notification,
		Items.RouteAdditionalInformation.EditText,
		TitleOfEditingForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenWarehouses(Command)
	
	FormParameters = New Structure("DocumentsArray, FormCaption",
		LadingWarehouses.UnloadValues(), NStr("vi = 'Kho bãi xếp hàng';
												|ru = 'Склады погрузки';
												|en = 'Lading warehouses'; fa = 'انبارهای بارگیری';
												|it = 'Magazzini di caricamento';
												|pl = 'Magazyny załadunku';
												|tr = 'Yükleme ambarları'"));
	OpenForm("CommonForm.ListOfCustomObjectsERP",
		FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure DistributeByTime(Command)
	
	ClearMessages();
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Route)
		And Not CheckSplitDeliveryPointServer() Then
		
		ReferenceAddress = PlaceOrdersInVault(Items.Route.CurrentData.ConnectionKey);
		FormParameters = New Structure("ReferenceAddress", ReferenceAddress);
		OpenForm("DataProcessor.WorkplaceOfDeliveryOfficer.Form.ReferencesChoiceForm", FormParameters, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UniteByTime(Command)
	
	ClearMessages();
	
	SelectedRows = Items.Route.SelectedRows;
	
	If SelectedRows.Count() < 2 Then
		CommonClientServer.MessageToUser(NStr("vi = 'Để hợp nhất, cần chọn ít nhất 2 dòng.';
												|ru = 'Для объединения необходимо выделить хотя бы 2 строки.';
												|en = 'Select at least 2 lines to merge.'; fa = 'Select at least 2 lines to merge.';
												|it = 'Per l''unione è necessario selezionare almeno 2 righe.';
												|pl = 'Dla połączenia należy wybrać przynajmniej 2 wierszy.';
												|tr = 'Birleştirmek için en az 2 satır seçilmelidir.'"));
		Return;
	EndIf;
	
	ReturnStructure = CheckBeforeMerging(SelectedRows);
	
	If ReturnStructure.DifferentAddresses Then
		
		CommonClient.MessageToUser(NStr("vi = 'Không thể hợp nhất các dòng được chọn: chọn các dòng có địa chỉ giống hệt nhau.';
										|ru = 'Не удалось объединить выделенные строки: выберите строки с одинаковыми адресами.';
										|en = 'Unable to merge the selected lines: select lines with the same addresses.'; fa = 'Unable to merge the selected lines: select lines with the same addresses.';
										|it = 'Non è stato possibile unificare le righe selezionate: scegliete le righe con gli stessi indirizzi.';
										|pl = 'Nie udało się połączyć wybrane wiersze: wybierz wiersze z jednakowymi adresami.';
										|tr = 'Seçilen satırlar birleştirilemedi: aynı adrese sahip satırları seçin.'"));
		Return;
		
	ElsIf ReturnStructure.DifferentData Then
		QuestionStr = NStr("vi = 'Các dòng đã chọn có nhiều giá trị dữ liệu (thời gian, thông tin bổ sung). Việc hợp nhất dòng dẫn đến làm mất tất cả các giá trị, ngoại trừ dòng đầu tiên. Tiếp tục?';
							|ru = 'Выделенные строки содержат несколько значений данных (время, доп. информация). Объединение строк приведет к потере всех значений, кроме первой строки. Продолжить?';
							|en = 'The selected lines contain a few data values (time, add. information). If you merge the lines, you will lose all the values except for the first line. Continue?'; fa = 'The selected lines contain a few data values (time, add. information). If you merge the lines, you will lose all the values except for the first line. Continue?';
							|it = 'Le righe selezionate contengono diversi valori di dati (tempo, informazioni aggiuntive). L''unificazione di righe comporterà la perdita di tutti i valori ad eccezione della prima riga. Continuare?';
							|pl = 'Wybrane wiersze zawierają kilka wartości danych (czas, informacja dodatkowa). Połączenie wierszy doprowadzi do utraty wszystkich wartości, oprócz pierwszego wiersza. Kontynuować?';
							|tr = 'Seçilen satırlar birkaç veri değeri içerir (zaman, ek bilgiler). Satırların birleştirilmesi, ilk satır dışındaki tüm değerlerin kaybolmasına neden olur. Devam edilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("UniteByTimeCompletion",
			ThisObject, New Structure("SelectedRows, ReturnStructure", SelectedRows, ReturnStructure)),
			QuestionStr, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	MergeByTimeFragment(SelectedRows, ReturnStructure);
	
EndProcedure

&AtClient
Procedure RouteDeliveredSetAll(Command)
	
	For Each Orders_Row In Object.References Do
		Orders_Row.Delivered = True;
	EndDo;
	
	For Each RouteString In Object.Route Do
		RouteString.Delivered = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure RouteDeliveredRemoveAll(Command)
	
	For Each Orders_Row In Object.References Do
		Orders_Row.Delivered = False;
	EndDo;
	
	For Each RouteString In Object.Route Do
		RouteString.Delivered = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInByGoodsIssueNotes(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.TransportationJob.DocumentForm.Command.FillInByGoodsIssueNotes");
	
	Mode = New ValueList; // Array of DialogReturnCode
	Mode.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại';
										|ru = 'Перезаполнить';
										|en = 'Refill'; fa = 'پرکردن مجدد';
										|it = 'Ricompilare';
										|pl = 'Refill';
										|tr = 'Yeniden doldur'"));
	Mode.Add(DialogReturnCode.No, NStr("vi = 'Không điền lại';
										|ru = 'Не перезаполнять';
										|en = 'Do not refill'; fa = 'Do not refill';
										|it = 'Non ricompilare';
										|pl = 'Nie wypełniaj ponownie';
										|tr = 'Yeniden doldurma'"));
	Text = NStr("vi = 'Điền lại nhiệm vụ cho các phiếu xuất liên quan cho hàng hóa?';
				|ru = 'Перезаполнить задание по связанным расходным ордерам на товары?';
				|en = 'Refill the job by the linked goods issue notes?'; fa = 'Refill the job by the linked goods issue notes?';
				|it = 'Ricompilare il task secondo le note di carico di merci?';
				|pl = 'Uzupełnij pracę o powiązane zamówienia towarów na wiersze pozycji?';
				|tr = 'İlgili ambar çıkış fişleri görevi yeniden doldurulsun mu?'");
	ShowQueryBox(New CallbackDescription("AfterQuestionOfReFillingOnOrders", ThisObject), Text, Mode);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.FilesOperations

// Parameters:
//   Command - FormCommand - executed command
//
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
Procedure CreateConsignmentNotes(Command)
	
	
EndProcedure

&AtClient
Procedure AddReference(Command)
	
	ClearMessages();
	
	If CheckTaskBlocking() Then
		
		If Not ValueIsFilled(Warehouse) Then
			ShowMessageBox(,NStr("vi = 'Trước khi chọn đơn hàng, bạn phải chỉ định kho.';
								|ru = 'Перед подбором распоряжений необходимо указать склад.';
								|en = 'Specify a warehouse before picking references.'; fa = 'Specify a warehouse before picking references.';
								|it = 'Prima di selezionare le disposizioni, è necessario specificare il magazzino.';
								|pl = 'Przed wyborem  zamówień należy wskazać magazyn.';
								|tr = 'Siparişleri seçmeden önce ambarı belirtmeniz gerekir.'"));
			Return;
		EndIf;
		
		OpenOrderSelectionForm();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Vehicle_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.JobIsPerformedBy");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTransportationJobAssignees.Carrier;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfTransportationJobs.BeingGenerated;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

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
Procedure UniteByTimeCompletion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	ReturnStructure = AdditionalParameters.ReturnStructure;
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	MergeByTimeFragment(SelectedRows, ReturnStructure);
	
EndProcedure

&AtClient
Procedure MergeByTimeFragment(Val SelectedRows, Val ReturnStructure)
	
	MergeRouteLines(SelectedRows,ReturnStructure.ArrayOfStringCodes)
	
EndProcedure

#Region TabularPartOfOrder

&AtClient
Procedure OpenOrderSelectionForm()
	
	FormParameters = New Structure();
	FormParameters.Insert("Warehouse",Warehouse);
	RouteCurLine = Items.Route.CurrentRow;
	If RouteCurLine <> Undefined Then
		FormParameters.Insert("Zone",Items.Route.CurrentData.Zone);
	EndIf;
	FormParameters.Insert("DeliveryKind", Object.Operation);
	FormParameters.Insert("TransportationJob", Object.Ref);
	FormParameters.Insert("FilterByAssigneeType", Object.JobIsPerformedBy);
	CallbackDescription = New CallbackDescription("AfterSelectingOrders", ThisObject);
	OpenForm("Document.TransportationJob.Form.ReferencesChoiceForm_", FormParameters,
		ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterSelectingOrders(ReturnStructure, AdditionalParameters) Export
	
	If ReturnStructure = Undefined Then
		Return;
	EndIf;
	
	AfterSelectingOrdersServer(ReturnStructure);
	
EndProcedure

&AtServer
Procedure AfterSelectingOrdersServer(ReturnStructure)
	
	References = GetFromTempStorage(ReturnStructure.ReferenceAddress);
	Goods = GetFromTempStorage(ReturnStructure.AddressOfGoods);
	
	Query = New Query(QueryTextModifiedAddedOrderLines());
	Query.SetParameter("SourceTable",Object.References.Unload());
	Query.SetParameter("SelectedOrders_3", References);
	Query.SetParameter("SourceGoods", GoodsToDeliver.Unload());
	Query.SetParameter("SelectedGoods", Goods);
	
	QueryResult = Query.ExecuteBatch();
	Modified = Not QueryResult[5].IsEmpty()
		Or Not QueryResult[6].IsEmpty()
		Or Not QueryResult[7].IsEmpty();
	
	ModifiedAddedLines = New Array; // Array of FormDataCollectionItem
	RouteString = Undefined;
	
	TheStructureOfTheSearch = New Structure("ReferenceOrder,Warehouse");
	
	FetchingModifiedRows = QueryResult[5].Select();
	
	While FetchingModifiedRows.Next() Do
		
		Orders_Row = Object.References[FetchingModifiedRows.LineNumber - 1];
		ChangeWeight = FetchingModifiedRows.Weight - Orders_Row.Weight;
		ChangingVolume = FetchingModifiedRows.VolumeM3 - Orders_Row.VolumeM3;
		FillPropertyValues(Orders_Row, FetchingModifiedRows);
		ChangeRouteWeightVolume(Orders_Row.ConnectionKey, ChangeWeight, ChangingVolume);
		
		FillPropertyValues(TheStructureOfTheSearch, Orders_Row);
		// The products will be re-added, we will delete the lines before the change
		For Each LineProducts_ In GoodsToDeliver.FindRows(TheStructureOfTheSearch) Do
			GoodsToDeliver.Delete(LineProducts_);
		EndDo;
		ModifiedAddedLines.Add(Orders_Row);
	EndDo;
	
	SelectionOfAddedRows = QueryResult[6].Select();
	While SelectionOfAddedRows.Next() Do
		
		Orders_Row = Object.References.Add(); 
		FillPropertyValues(Orders_Row, SelectionOfAddedRows);
		
		RouteString = GoodsDelivery.AddEditItemByDeliveryDetails(
			Object.Route, SelectionOfAddedRows, Object.PlanTripStartTime);
		
		Orders_Row.ConnectionKey = RouteString.ConnectionKey;
		
		ModifiedAddedLines.Add(Orders_Row);
		
	EndDo;
	
	ItemsOfAmendedAndAddedOrders = QueryResult[7].Unload();
	CommonClientServer.SupplementTable(ItemsOfAmendedAndAddedOrders, GoodsToDeliver);
	
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	
	UpgradeLoadingDepots();
	FillInServiceDetailsOfRoute();
	GoodsDelivery.ThisAttributeIsDeliveredInFull(ItemsOfAmendedAndAddedOrders,
		Object.References, ModifiedAddedLines);
	
	If RouteString <> Undefined Then
		Items.Route.CurrentRow = RouteString.GetID();
	EndIf;
	
EndProcedure

&AtServer
Function QueryTextModifiedAddedOrderLines()
	
	QueryText =
	"SELECT
	|	SourceTable.LineNumber,
	|	SourceTable.ReferenceOrder,
	|	SourceTable.Warehouse,
	|	SourceTable.Weight,
	|	SourceTable.VolumeM3
	|INTO SourceTable
	|FROM
	|	&SourceTable AS SourceTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectedOrders_3.ReferenceOrder,
	|	SelectedOrders_3.Weight,
	|	SelectedOrders_3.VolumeM3,
	|	SelectedOrders_3.Carrier,
	|	SelectedOrders_3.RecipientSender,
	|	SelectedOrders_3.TimeFrom,
	|	SelectedOrders_3.TimeTo,
	|	SelectedOrders_3.AdditionalInformation,
	|	SelectedOrders_3.Warehouse,
	|	SelectedOrders_3.Address,
	|	SelectedOrders_3.FieldValueAddress,
	|	SelectedOrders_3.Zone
	|INTO SelectedOrders_3
	|FROM
	|	&SelectedOrders_3 AS SelectedOrders_3
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SourceGoods.ReferenceOrder,
	|	SourceGoods.Warehouse,
	|	SourceGoods.RecipientSender,
	|	SourceGoods.Products,
	|	SourceGoods.Characteristic,
	|	SourceGoods.Purpose,
	|	SourceGoods.Series,
	|	SourceGoods.Count,
	|	SourceGoods.AllGoods
	|INTO SourceGoods
	|FROM
	|	&SourceGoods AS SourceGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectedGoods.ReferenceOrder,
	|	SelectedGoods.Warehouse,
	|	SelectedGoods.RecipientSender,
	|	SelectedGoods.Products,
	|	SelectedGoods.Characteristic,
	|	SelectedGoods.Purpose,
	|	SelectedGoods.Series,
	|	SelectedGoods.Count,
	|	SelectedGoods.AllGoods
	|INTO SelectedGoods
	|FROM
	|	&SelectedGoods AS SelectedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersCollapsed.ReferenceOrder,
	|	OrdersCollapsed.Warehouse,
	|	SUM(OrdersCollapsed.Weight) AS Weight,
	|	SUM(OrdersCollapsed.VolumeM3) AS VolumeM3,
	|	MAX(CASE
	|			WHEN SourceTable.ReferenceOrder IS NULL 
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS ChangedRow
	|INTO OrdersCollapsed
	|FROM
	|	SelectedOrders_3 AS OrdersCollapsed
	|		LEFT JOIN SourceTable AS SourceTable
	|		ON (SourceTable.ReferenceOrder = OrdersCollapsed.ReferenceOrder)
	|			AND (SourceTable.Warehouse = OrdersCollapsed.Warehouse)
	|
	|GROUP BY
	|	OrdersCollapsed.Warehouse,
	|	OrdersCollapsed.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ModifiedRows.Weight,
	|	ModifiedRows.VolumeM3,
	|	SourceTable.LineNumber
	|FROM
	|	OrdersCollapsed AS ModifiedRows
	|		INNER JOIN SourceTable AS SourceTable
	|		ON (SourceTable.ReferenceOrder = ModifiedRows.ReferenceOrder)
	|			AND (SourceTable.Warehouse = ModifiedRows.Warehouse)
	|WHERE
	|	ModifiedRows.ChangedRow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LinesToAdd.ReferenceOrder,
	|	OrdersCollapsed.Weight,
	|	LinesToAdd.VolumeM3,
	|	LinesToAdd.Carrier,
	|	LinesToAdd.RecipientSender,
	|	LinesToAdd.TimeFrom,
	|	LinesToAdd.TimeTo,
	|	LinesToAdd.AdditionalInformation,
	|	LinesToAdd.Warehouse,
	|	LinesToAdd.Address,
	|	LinesToAdd.FieldValueAddress,
	|	LinesToAdd.Zone,
	|	LinesToAdd.ReferenceOrder REFS Document.InstructionForShippingAgent AS ThisIsInstructionForShippingAgent
	|FROM
	|	SelectedOrders_3 AS LinesToAdd
	|		INNER JOIN OrdersCollapsed AS OrdersCollapsed
	|		ON (OrdersCollapsed.ReferenceOrder = LinesToAdd.ReferenceOrder)
	|			AND (OrdersCollapsed.Warehouse = LinesToAdd.Warehouse)
	|			AND (NOT OrdersCollapsed.ChangedRow)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectedGoods.ReferenceOrder,
	|	SelectedGoods.Warehouse,
	|	SelectedGoods.RecipientSender,
	|	SelectedGoods.Products,
	|	SelectedGoods.Characteristic,
	|	SelectedGoods.Purpose,
	|	SelectedGoods.Series,
	|	SelectedGoods.Count,
	|	SelectedGoods.AllGoods
	|FROM
	|	SelectedGoods AS SelectedGoods";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region TabularPartOfRoute

&AtServer 
Procedure RouteBeforeDeletionOnServer(Val SelectedRows)
	
	For Each RowID In SelectedRows Do
		
		CurrentRow = Object.Route.FindByID(RowID);
		
		ConnectionKey = CurrentRow.ConnectionKey;
		
		Object.Route.Delete(CurrentRow);
		
		TheStructureOfTheSearch = New Structure("ReferenceOrder, Warehouse");
		FoundRows = Object.References.FindRows(New Structure("ConnectionKey",ConnectionKey));
		For Each Orders_Row In FoundRows Do
			Object.References.Delete(Orders_Row);
			FillPropertyValues(TheStructureOfTheSearch, Orders_Row);
			FoundProductLines = GoodsToDeliver.FindRows(TheStructureOfTheSearch);
			For Each LineProducts_ In FoundProductLines Do
				GoodsToDeliver.Delete(LineProducts_);
			EndDo;
		EndDo;
	EndDo;
	
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	
	UpgradeLoadingDepots();
	
EndProcedure

&AtServer
Function CheckSplitDeliveryPointServer()
	
	ConnectionKey = Object.Route.FindByID(Items.Route.CurrentRow).ConnectionKey;
	NumberOfReferences = Object.References.FindRows(New Structure("ConnectionKey",ConnectionKey)).Count();
	If NumberOfReferences < 2 Then
		
		Text = NStr("vi = 'Có thể phân chia dòng đối với địa chỉ, mà có liên quan đến hơn một lệnh';
					|ru = 'Разбиение строки возможно для адресов, к которым относится более одного распоряжения';
					|en = 'Line split is available for addresses with more than one reference'; fa = 'Line split is available for addresses with more than one reference';
					|it = 'La divisione della riga è possibile per gli indirizzi ai quali si riferisce più di un riferimento.';
					|pl = 'Podział wiersza jest możliwy dla adresów, do których odnosi się więcej niż jedno zamówienie';
					|tr = 'Birden fazla emrin geçerli olduğu adresler için satır bölme mümkündür'");
		Common.MessageToUser(Text);
		Return True;
		
	EndIf;
	If NumberOfReferences > 2 Then
		Return False; //Return to the client and open the order selection form
	EndIf;
	ReferenceArray = New Array;
	Filter = New Structure("ConnectionKey", ConnectionKey);
	OrderLine_2 = Object.References.FindRows(Filter)[1];
	ReferenceArray.Add(New Structure("ReferenceOrder,Warehouse", OrderLine_2.ReferenceOrder, OrderLine_2.Warehouse));
	SplitDeliveryPoint(ReferenceArray); // The case with two orders - just split without a choice
	
	Return True;
	
EndFunction

&AtServer
Procedure SplitDeliveryPoint(References)
	
	If TypeOf(References) <> Type("Array") Then
		ReferenceArray = New Array;
		For Each String In GetFromTempStorage(References.ReferenceAddress) Do
			ReferenceArray.Add(New Structure("ReferenceOrder,Warehouse", String.ReferenceOrder, String.Warehouse));
		EndDo;	
	Else
		ReferenceArray = References;
	EndIf;
	
	RouteLineID = Items.Route.CurrentRow;
	
	RouteString = Object.Route.FindByID(RouteLineID);
	NewRow = Object.Route.Add();
	FillPropertyValues(NewRow,RouteString);
	ConnectionKey = String(New UUID);
	NewRow.ConnectionKey = ConnectionKey;
	
	For Each StructureSearch In ReferenceArray Do
		Orders_Row = Object.References.FindRows(StructureSearch)[0];
		Orders_Row.ConnectionKey = ConnectionKey;
	EndDo;
	
	Items.Route.CurrentRow = NewRow.GetID();
	
	UpdateRouteLineWeightAndVolume(RouteString);
	UpdateRouteLineWeightAndVolume(NewRow);
	LinesBeingUpdated = New Array;
	LinesBeingUpdated.Add(RouteString);
	LinesBeingUpdated.Add(NewRow);
	FillInServiceDetailsOfRoute(LinesBeingUpdated);
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	
EndProcedure

&AtClient
Function CheckBeforeMerging(SelectedRows)
	
	URLMap = New Map;
	MatchingDeliveryZones = New Map;
	MatchingTimeWith = New Map;
	MatchingTimeBy = New Map;
	ComplianceAdditionalInformation = New Map;
	ComplianceDelivered = New Map;	
	
	ArrayOfStringCodes = New Array;
	ReturnStructure = New Structure;
	
	For Each Id In SelectedRows Do
		
		Orders_Row = Object.Route.FindByID(Id);
		
		URLMap.Insert(Orders_Row.Address,"");
		MatchingDeliveryZones.Insert(Orders_Row.Zone,"");
		MatchingTimeWith.Insert(Orders_Row.TimeFrom,"");
		MatchingTimeBy.Insert(Orders_Row.TimeTo,"");
		ComplianceAdditionalInformation.Insert(Orders_Row.AdditionalInformation,"");
		ComplianceDelivered.Insert(Orders_Row.Delivered,"");
		
		ArrayOfStringCodes.Add(Orders_Row.ConnectionKey);
		
	EndDo;
		
	If URLMap.Count()>1 Then
		ReturnStructure.Insert("DifferentAddresses",True);
		Return ReturnStructure;
	ElsIf MatchingDeliveryZones.Count()>1
			Or MatchingTimeWith.Count() > 1
			Or MatchingTimeBy.Count() > 1
			Or ComplianceAdditionalInformation.Count()>1
			Or ComplianceDelivered.Count() > 1
			Or MatchingDeliveryZones.Count() > 1 Then
		ReturnStructure.Insert("DifferentAddresses",False);
		ReturnStructure.Insert("DifferentData",True);
	Else
		ReturnStructure.Insert("DifferentAddresses",False);
		ReturnStructure.Insert("DifferentData",False);
	EndIf;
	
	ReturnStructure.Insert("ArrayOfStringCodes",ArrayOfStringCodes);
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function MergeRouteLines(SelectedRows,ArrayOfStringCodes)
	
	RouteString = Object.Route.FindByID(SelectedRows[0]);
	NewCommunicationKey_ = RouteString.ConnectionKey;
	RouteString.Weight = 0;
	RouteString.VolumeM3 = 0;
	
	For Each Orders_Row In Object.References Do
		
		If ArrayOfStringCodes.Find(Orders_Row.ConnectionKey)<>Undefined Then
			Orders_Row.ConnectionKey = NewCommunicationKey_;
			RouteString.Weight = RouteString.Weight + Orders_Row.Weight;
			RouteString.VolumeM3 = RouteString.VolumeM3 + Orders_Row.VolumeM3;
		EndIf;	
		
	EndDo;	
	
	LineSkipped = False;
	For Each Id In SelectedRows Do
		If Not LineSkipped Then
			LineSkipped = True;
			Continue;
		EndIf;
		
		Object.Route.Delete(Object.Route.FindByID(Id));
		
	EndDo;
	
	LinesBeingUpdated = New Array;
	LinesBeingUpdated.Add(RouteString);
	FillInServiceDetailsOfRoute(LinesBeingUpdated);
	
EndFunction

&AtClient
Procedure SortRouteList()
	
	Object.Route.Sort("TimeFrom, TimeTo, Address");
	
EndProcedure

&AtClient
Procedure WhenChangingTimeFrom()
	
	CurRouteLine = Items.Route.CurrentData;
	CurRouteLine.TimeFrom = BegOfDay(CurRouteLine.TimeFrom)
		+ Hour(CurRouteLine.TimeFromWithoutDate)*60*60 + Minute(CurRouteLine.TimeFromWithoutDate)*60;
		
	If CurRouteLine.TimeTo < CurRouteLine.TimeFrom Then
		CurRouteLine.TimeTo = CurRouteLine.TimeFrom;
		CurRouteLine.TimeToWithoutDate = CurRouteLine.TimeFromWithoutDate;
	EndIf;
	
	If CurRouteLine.TimeFrom < Object.PlanTripStartTime Then
		Object.PlanTripStartTime = CurRouteLine.TimeFrom;
		ShowUserNotification(NStr("vi = 'Đã thay đổi ngày dự tính bắt đầu đánh giá ';
									|ru = 'Плановая дата начала рейса изменена';
									|en = 'Planned trip start date is changed'; fa = 'Planned trip start date is changed';
									|it = 'Data prevista dell''inizio di viaggio è stata modificata';
									|pl = 'Planowa data początku rejsu została zmieniona';
									|tr = 'Planlı seyahat başlangıç ​​tarihi değişti'"),,
			NStr("vi = 'Ngày đã chọn sớm hơn ngày dự tính kết thúc chuyến hàng.';
				|ru = 'Выбранная дата раньше плановой даты начала рейса.';
				|en = 'The selected date is before the planned trip start date.'; fa = 'The selected date is before the planned trip start date.';
				|it = 'La data selezionata è antecedente alla data dell''inizio di viaggio prevista.';
				|pl = 'Wybrana data jest wcześniej niż planowa data początku rejsu.';
				|tr = 'Seçilen tarih, seyahatin planlanan başlangıç ​​tarihinden daha erken.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingDefaultTime()
	
	CurRouteLine = Items.Route.CurrentData;
	CurRouteLine.TimeTo = BegOfDay(CurRouteLine.TimeTo)
		+ Hour(CurRouteLine.TimeToWithoutDate)*60*60 + Minute(CurRouteLine.TimeToWithoutDate)*60;
	
	If CurRouteLine.TimeTo < CurRouteLine.TimeFrom Then
		CurRouteLine.TimeFrom = CurRouteLine.TimeTo;
		CurRouteLine.TimeFromWithoutDate = CurRouteLine.TimeToWithoutDate;
	EndIf;
	
	If Object.PlanTripStartTime <> '00010101' And Object.PlanTripEndTime < CurRouteLine.TimeTo Then
		Object.PlanTripEndTime = CurRouteLine.TimeTo;
		ShowUserNotification(NStr("vi = 'Đã thay đổi ngày dự tính kết thúc chuyển hàng';
									|ru = 'Плановая дата окончания рейса изменена';
									|en = 'Planned trip end date is changed'; fa = 'Planned trip end date is changed';
									|it = 'La data prevista del termine di viaggio è stata modificata';
									|pl = 'Planowa data zakończenia rejsu została zmieniona';
									|tr = 'Seyahatin planlanan bitiş tarihi değiştirildi'"),,
			NStr("vi = 'Ngày đã chọn muộn hơn ngày dự tính kết thúc chuyển hàng.';
				|ru = 'Выбранная дата позже плановой даты окончания рейса.';
				|en = 'The selected date is later than the planned trip end date.'; fa = 'The selected date is later than the planned trip end date.';
				|it = 'La data selezionata è postuma alla data prevista del termine di viaggio.';
				|pl = 'Wybrana data jest później niż planowa data zakończenia rejsu.';
				|tr = 'Seçilen tarih, seyahatin planlanan bitiş tarihinden sonra.'"));
	EndIf;
	
EndProcedure	

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	BoldFont = StyleFonts.BoldFont;
	ColorGreen = StyleColors.SuccessResultColor;
	ColorRed = StyleColors.ResultIssueColor;
	
	UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	TonConversionFactor     			 = GoodsDelivery.TonConversionFactor();
	CubicMeterConversionFactor     = GoodsDelivery.CubicMeterConversionFactor();
		
	VehicleDetails = GoodsDelivery.VehicleDetails(Object.Vehicle_);
	FillPropertyValues(ThisObject,VehicleDetails);
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	DisplayUserNameOnServer(ThisObject);
	
	TitleText = NStr("vi = 'Khối lượng, %UnitOfMeasureForVolume%';
					|ru = 'Объем, %UnitOfMeasureForVolume%';
					|en = 'Volume, %UnitOfMeasureForVolume%'; fa = 'Volume, %UnitOfMeasureForVolume%';
					|it = 'Volume, %UnitOfMeasureForVolume%';
					|pl = 'Objętość, %UnitOfMeasureForVolume%';
					|tr = 'Hacim, %UnitOfMeasureForVolume%'");
	TitleText = StrReplace(TitleText, "%UnitOfMeasureForVolume%", String(UnitOfMeasureForVolume));
	Items.RouteVolumeM3.Title = TitleText;
	
	TitleText = NStr("vi = 'Trọng lượng, %UnitOfMeasureForWeight%';
					|ru = 'Вес, %UnitOfMeasureForWeight%';
					|en = 'Weight, %UnitOfMeasureForWeight%'; fa = 'Weight, %UnitOfMeasureForWeight%';
					|it = 'Peso, %UnitOfMeasureForWeight%';
					|pl = 'Waga, %UnitOfMeasureForWeight%';
					|tr = 'Ağırlık, %UnitOfMeasureForWeight%'");
	TitleText = StrReplace(TitleText, "%UnitOfMeasureForWeight%", String(UnitOfMeasureForWeight));
	Items.RouteWeight.Title = TitleText;
	
	Warehouse = Object.Warehouse;
	Carrier = Object.Carrier;
	
	If Not ValueIsFilled(Object.EmployeeResponsible) Then
		Object.EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	FillInServiceDetailsOfRoute();
	
	StatusWas = Object.Status;
	
	UpgradeLoadingDepots();
	
	If Object.Operation = Enums.DeliveryKinds.ToWarehouse Then
		Items.RouteRecipientsSenders.Title      = NStr("vi = 'Người gửi';
														|ru = 'Отправители';
														|en = 'Senders'; fa = 'Senders';
														|it = 'Mittenti';
														|pl = 'Senders';
														|tr = 'Gönderenler'");
		Items.Status.ChoiceList.Clear();
		Items.Status.ChoiceList.Add(Enums.StatusesOfTransportationJobs.BeingGenerated);
		Items.Status.ChoiceList.Add(Enums.StatusesOfTransportationJobs.Sent);
		Items.Status.ChoiceList.Add(Enums.StatusesOfTransportationJobs.Closed);
	Else
		Items.RouteRecipientsSenders.Title      = NStr("vi = 'Người nhận';
														|ru = 'Получатели';
														|en = 'Recipients'; fa = 'گیرندگان';
														|it = 'Destinatari';
														|pl = 'Recipients';
														|tr = 'Alıcılar'");
		Items.Status.ChoiceList.Clear();
		Items.Status.ChoiceList.Add(Enums.StatusesOfTransportationJobs.BeingGenerated);
		Items.Status.ChoiceList.Add(Enums.StatusesOfTransportationJobs.ToLoad);
		Items.Status.ChoiceList.Add(Enums.StatusesOfTransportationJobs.Sent);
		Items.Status.ChoiceList.Add(Enums.StatusesOfTransportationJobs.Closed);
	EndIf;
	
	ConfigureByArtistType();
	
	OnReadCreateAtServerLocalization();
	
EndProcedure

&AtServer
Procedure VehicleWhenModifiedOnServer()
	
	TTNParameters = New Structure;
	TTNParameters.Insert("VehicleRegPlate");
	TTNParameters.Insert("VehicleModel");	
	TTNParameters.Insert("TransportationType");
	TTNParameters.Insert("VehicleType");
	TTNParameters.Insert("VehicleCubicMetresCapacity");
	TTNParameters.Insert("VehicleCarryingCapacityInTons");
	TTNParameters.Insert("LicenseCardSeries");
	TTNParameters.Insert("LicenseCardNumber");
	TTNParameters.Insert("LicenseCardKind");
	TTNParameters.Insert("RegistrationNumberOfLicenseCard");
	TTNParameters.Insert("Trailer");
	TTNParameters.Insert("TrailerRegPlate");
	
	If ValueIsFilled(Object.Vehicle_) Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Vehicles.Code AS VehicleRegPlate,
		|	Vehicles.Brand AS VehicleModel,
		|	Vehicles.TransportationType AS TransportationType,
		|	Vehicles.Type AS VehicleType,
		|	Vehicles.CapacityInCubicMeters AS VehicleCubicMetresCapacity,
		|	Vehicles.CarryingCapacityInTons AS VehicleCarryingCapacityInTons,
		|	Vehicles.LicenseCardKind,
		|	Vehicles.LicenseCardNumber,
		|	Vehicles.RegistrationNumberOfLicenseCard,
		|	Vehicles.LicenseCardSeries,
		|	Vehicles.Trailer,
		|	Vehicles.TrailerRegPlate AS TrailerRegPlate
		|FROM
		|	Catalog.Vehicles AS Vehicles
		|WHERE
		|	Vehicles.Ref = &Ref
		|
		|UNION ALL
		|
		|SELECT
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	VehicleTypes.Description,
		|	VehicleTypes.CapacityInCubicMeters,
		|	VehicleTypes.CarryingCapacityInTons,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED
		|FROM
		|	Catalog.VehicleTypes AS VehicleTypes
		|WHERE
		|	VehicleTypes.Ref = &Ref";
		
		Query.SetParameter("Ref", Object.Vehicle_);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			FillPropertyValues(TTNParameters, Selection);
		EndIf;			
	EndIf;
	
	FillPropertyValues(Object, TTNParameters);
	
	CarryingCapacityInUserUnit = Object.VehicleCarryingCapacityInTons / TonConversionFactor;
	CapacityInUserUnits = Object.VehicleCubicMetresCapacity / CubicMeterConversionFactor;
	
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	DisplayUserNameOnServer(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTotalWeightVolumeOccupancy(Form)
	
	Weight = Form.Object.Route.Total("Weight");
	VolumeM3 = Form.Object.Route.Total("VolumeM3");
	Form.Object.Weight   = Weight * Form.TonConversionFactor;
	Form.Object.VolumeM3 = VolumeM3 * Form.CubicMeterConversionFactor;
	
	DataWeightVolume = New Structure;
	DataWeightVolume.Insert("CarryingCapacityInUserUnit", Form.CarryingCapacityInUserUnit);
	DataWeightVolume.Insert("CapacityInUserUnits", Form.CapacityInUserUnits);
	DataWeightVolume.Insert("Weight", Weight);
	DataWeightVolume.Insert("VolumeM3", VolumeM3);
	
	GoodsDeliveryClientServer.DisplayUnderloadOverload(Form, DataWeightVolume)
	
EndProcedure	

&AtServer
Procedure UpdateRouteLineWeightAndVolume(RouteString)
	
	OrderLines_2 = Object.References.FindRows(New Structure("ConnectionKey",RouteString.ConnectionKey));
	
	RouteString.Weight = 0;
	RouteString.VolumeM3 = 0;
		
	For Each Orders_Row In OrderLines_2 Do
		
		RouteString.Weight = Orders_Row.Weight + RouteString.Weight;
		RouteString.VolumeM3 = Orders_Row.VolumeM3 + RouteString.VolumeM3;
		
	EndDo;	 
		 	
EndProcedure

&AtServer
Function PlaceOrdersInVault(ConnectionKey)
	
	StructureSearch = New Structure("ConnectionKey",ConnectionKey);
	References = Object.References.Unload(StructureSearch);
	
	Return PutToTempStorage(References, UUID);

EndFunction

// Parameters:
//  QuestionResult  - DialogReturnCode
//  AdditionalParameters - Arbitrary
//
&AtClient
Procedure WarehouseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		
		Object.Warehouse = Warehouse;
		Return;
		
	Else
		
		Warehouse = Object.Warehouse;
		
	EndIf;
	
	WhenChangingWarehouseServer();
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseServer()
	
	Object.References.Clear();
	Object.Route.Clear();
	GoodsToDeliver.Clear();
	Object.Weight = 0;
	Object.VolumeM3 = 0;
	
	UpgradeLoadingDepots();
	
EndProcedure

&AtServer
Procedure UpgradeLoadingDepots()
	
	Warehouses = Object.References.Unload(,"Warehouse");
	Warehouses.GroupBy("Warehouse");
	LadingWarehouses.LoadValues(Warehouses.UnloadColumn("Warehouse"));
	
	WarehouseGroup_ = Common.ObjectAttributeValue(Warehouse, "IsFolder");
	ThereAreAdvancedWarehouses = WarehousesServer.ThereIsOrderWarehouseForShipment(Warehouse, Object.PlanTripStartTime);
		
	Items.PictureMultipleWarehouses.Visible = ?(WarehouseGroup_ = Undefined, False, WarehouseGroup_);
	Items.OpenWarehouses.Visible = ?(WarehouseGroup_ = Undefined, False, WarehouseGroup_);
	Items.FillOutOrdersForExpenditureOrders.Visible = 
		(ThereAreAdvancedWarehouses
		 And Object.Operation = Enums.DeliveryKinds.FromWarehouse);
	Items.FillOutOrdersForExpenditureOrders.Enabled = ValueIsFilled(Object.Ref);
	
	If Object.Operation = Enums.DeliveryKinds.ToWarehouse Then
		TitleText = NStr("vi = 'Kho đích (%WarehousesQuantity%)';
						|ru = 'Склады назначения (%WarehousesQuantity%)';
						|en = 'Destination warehouses (%WarehousesQuantity%)'; fa = 'Destination warehouses (%WarehousesQuantity%)';
						|it = 'Magazzini di destinazione (%WarehousesQuantity%)';
						|pl = 'Magazyny przeznaczenia (%WarehousesQuantity%)';
						|tr = 'Hedef ambarları (%WarehousesQuantity%)'");
	Else
		TitleText = NStr("vi = 'Kho bãi xếp hàng (%WarehousesQuantity%)';
						|ru = 'Склады погрузки (%WarehousesQuantity%)';
						|en = 'Lading warehouses (%WarehousesQuantity%)'; fa = 'Lading warehouses (%WarehousesQuantity%)';
						|it = 'Magazzini di caricamento (%WarehousesQuantity%)';
						|pl = 'Magazyny ładowania (%WarehousesQuantity%)';
						|tr = 'Yükleme ambarları (%WarehousesQuantity%)'");
	EndIf;
	TitleText = StrReplace(TitleText, "%WarehousesQuantity%", String(Warehouses.Count()));
	Items.OpenWarehouses.Title = TitleText;
	
EndProcedure

// Parameters:
//  The result of the query is the code of the return of the radio
//  AdditionalParameters - Arbitrary
//
&AtClient
Procedure AfterQuestionOfReFillingOnOrders(Result, AdditionalParameters) Export
	
	NotificationText1 = WhenChangingStatusAndOverfilling(Result = DialogReturnCode.Yes);
	
	NotifyAboutChanges_(NotificationText1);
	
EndProcedure

&AtClient
Procedure NotifyAboutChanges_(NotificationText1)
	
	If Not IsBlankString(NotificationText1) Then
		ShowUserNotification(,,
			NotificationText1,
			PictureLib.Information32);
	EndIf;

EndProcedure

&AtServer
Function WhenChangingStatusAndOverfilling(ReFillForSpendingOrders = False)
	
	TextOfMessageAboutReFillingOrders = "";
	If ReFillForSpendingOrders Then
		If FillBySpendingOrdersOnServer() Then
			If Object.References.Count() > 0 Then
				TextOfMessageAboutReFillingOrders = NStr("vi = 'Nhiệm vụ vận chuyển đã được bổ sung cho hàng tiêu dùng cho hàng hóa.';
														|ru = 'Задание на перевозку перезаполнено по расходным ордерам на товары.';
														|en = 'Itinerary is refilled by goods issue notes.'; fa = 'Itinerary is refilled by goods issue notes.';
														|it = 'Il task per il trasporto è ricompilato per i mandati di pagamento per le merci.';
														|pl = 'Zadanie na przewóz jest ponownie wypełnione według wydania zewnętrznego.';
														|tr = 'Ambar çıkış fişi için taşıma planı yeniden dolduruldu.'");
			Else
				TextOfMessageAboutReFillingOrders = NStr("vi = 'Sau khi bổ sung các lệnh chi tiêu cho hàng hóa trong lệnh vận chuyển, không có lệnh để giao hàng.';
														|ru = 'После перезаполнения по расходным ордерам на товары в задании на перевозку не осталось распоряжений на доставку.';
														|en = 'There are no delivery references left in the itinerary after repopulation by goods issue notes.'; fa = 'There are no delivery references left in the itinerary after repopulation by goods issue notes.';
														|it = 'Dopo la ricompilazione per i mandati di pagamento per le merci, nel task di trasporto non vi sono rimaste le disposizioni per la consegna.';
														|pl = 'Po ponownym wypełnieniu według zleceń wydania na wiersze pozycji w zadaniu na przewóz nie pozostało zamówień na dostawę.';
														|tr = 'Ambar çıkış fişi yeniden doldurduktan sonra, taşıma planında teslimat emri kalmadı.'");
			EndIf;
		Else
			TextOfMessageAboutReFillingOrders = NStr("vi = 'Nhiệm vụ vận chuyển không được bổ sung vì tương ứng với lệnh chi phí cho hàng hóa.';
													|ru = 'Задание на перевозку не перезаполнено, т.к. соответствует расходным ордерам на товары.';
													|en = 'Itinerary is not refilled as it corresponds to goods issue notes.'; fa = 'Itinerary is not refilled as it corresponds to goods issue notes.';
													|it = 'Il task per il trasporto è ricompilato perché corrisponde ai mandati di pagamento per le merci.';
													|pl = 'Zadanie na przewóz nie jest ponownie wypełnione ponieważ nie odpowiada wydaniom zewnętrznym.';
													|tr = 'Taşıma planı yeniden doldurulmadı çünkü ambar çıkış fişi siparişlerine karşılık geliyor.'");
		EndIf;
	EndIf;
	
	If StatusWas = Object.Status Then
		Return TextOfMessageAboutReFillingOrders;
	EndIf;
	
	StatusWas = Object.Status;
	
	TimeMessageText = Documents.TransportationJob.FillInFlightTimePlanFact(Object);
	
	Return TimeMessageText;
	
EndFunction

&AtServer
Procedure FillInServiceDetailsOfRoute(LinesBeingUpdated = Undefined)
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager; 
	Query.Text =
	"SELECT
	|	References.ReferenceOrder AS ReferenceOrder,
	|	References.Warehouse AS Warehouse,
	|	References.Carrier AS Carrier,
	|	References.RecipientSender AS RecipientSender,
	|	References.ConnectionKey AS ConnectionKey,
	|	References.LineNumber AS LineNumber
	|INTO References
	|FROM
	|	&References AS References
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Route.Address AS Address,
	|	Route.AddressValue AS AddressValue,
	|	Route.FieldValueAddress AS FieldValueAddress,
	|	Route.LineNumber AS LineNumber,
	|	Route.ConnectionKey AS ConnectionKey
	|INTO Route
	|FROM
	|	&Route AS Route
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&TransportationJob AS TransportationJob,
	|	References.ReferenceOrder AS ReferenceOrder,
	|	References.Warehouse AS Warehouse,
	|	References.Carrier AS CarrierPartner,
	|	References.RecipientSender AS RecipientSender,
	|	References.LineNumber AS OrderLineNumber,
	|	Route.Address AS DeliveryAddress,
	|	Route.AddressValue AS DeliveryAddressValue,
	|	Route.FieldValueAddress AS DeliveryAddressFieldValues,
	|	Route.LineNumber AS RouteLineNumber
	|INTO YourRoute
	|FROM
	|	Route AS Route
	|		INNER JOIN References AS References
	|		ON Route.ConnectionKey = References.ConnectionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	YourRoute.OrderLineNumber AS OrderLineNumber,
	|	MAX(YourRoute.RouteLineNumber) AS RouteLineNumber,
	|	MAX(YourRoute.CarrierPartner) AS Carrier,
	|	MAX(YourRoute.RecipientSender) AS RecipientSender
	|FROM
	|	YourRoute AS YourRoute
	|
	|GROUP BY
	|	YourRoute.OrderLineNumber
	|
	|ORDER BY
	|	RouteLineNumber,
	|	OrderLineNumber,
	|	MAX(YourRoute.CarrierPartner),
	|	MAX(YourRoute.RecipientSender)";
	
	Query.SetParameter("References", Object.References.Unload());
	If LinesBeingUpdated = Undefined Then
		Query.SetParameter("Route", Object.Route.Unload());
	Else
		Query.SetParameter("Route", Object.Route.Unload(LinesBeingUpdated));
	EndIf;
	
	Query.SetParameter("TransportationJob",	Object.Ref);
		
	Result = Query.Execute().Select();
	TemplateWithCarrier = NStr("vi = '%Carrier% (cho %RecipientsSenders%)';
								|ru = '%Carrier% (для %RecipientsSenders%)';
								|en = '%Carrier% (for %RecipientsSenders%)'; fa = '%Carrier% (for %RecipientsSenders%)';
								|it = '%Carrier% (per %RecipientsSenders%)';
								|pl = '%Carrier% (dla %RecipientsSenders%)';
								|tr = '%Carrier% (%RecipientsSenders% için)'");
	While Result.NextByFieldValue("RouteLineNumber") Do
		
		RouteString = Object.Route[Result.RouteLineNumber - 1];
		RecipientsSendersByItem = "";
		NumberOfReferences = 0;
		
		While Result.NextByFieldValue("Carrier") Do
			
			RecipientsSendersByCarrier = "";
			While Result.NextByFieldValue("RecipientSender") Do
				
				While Result.Next() Do
					NumberOfReferences = NumberOfReferences + 1;
				EndDo;
				
				RecipientsSendersByCarrier = RecipientsSendersByCarrier + Result.RecipientSender + "," + " ";
			EndDo;
			RecipientsSendersByCarrier = Left(RecipientsSendersByCarrier, StrLen(RecipientsSendersByCarrier)-2);
			If ValueIsFilled(Result.Carrier) Then
				RecipientsSendersByCarrier = StrReplace(TemplateWithCarrier, "%RecipientsSenders%", RecipientsSendersByCarrier);
				RecipientsSendersByCarrier = StrReplace(RecipientsSendersByCarrier, "%Carrier%", Result.Carrier);
			EndIf;
			RecipientsSendersByItem = RecipientsSendersByItem + RecipientsSendersByCarrier + "," + " ";
		EndDo;
		
		RouteString.RecipientsSenders = RecipientsSendersByItem
			+ StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(NumberOfReferences, NStr("vi = 'lệnh, lệnh, lệnh';
																											|ru = 'распоряжение, распоряжения, распоряжений';
																											|en = 'reference, reference, references'; fa = 'reference, reference, references';
																											|it = 'disposizione, disposizioni, disposizioni';
																											|pl = 'zamówienie, zamówienia, zamówień';
																											|tr = 'sipariş, siparişler, siparişlerin'"))
			+ NStr("vi = '...';
					|ru = '...';
					|en = '...'; fa = '...';
					|it = '...';
					|pl = '...';
					|tr = '...'");
		
		RouteString.TimeFromWithoutDate   = GoodsDeliveryClientServer.TimeWithoutDate(RouteString.TimeFrom);
		RouteString.TimeToWithoutDate  = GoodsDeliveryClientServer.TimeWithoutDate(RouteString.TimeTo);
		
	EndDo;
	
	FillInServiceDetailsOfRouteLocalization(TempTablesManager);
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForDelivery()
	
	Return PutToTempStorage(GoodsToDeliver.Unload());
	
EndFunction

&AtServer
Procedure ChangeRouteWeightVolume(ConnectionKey, ChangeWeight, ChangingVolume)
	
	RouteString = RouteStringByLinkKey(ConnectionKey);
	RouteString.Weight = RouteString.Weight + ChangeWeight;
	RouteString.VolumeM3 = RouteString.VolumeM3 + ChangingVolume;
	
EndProcedure

&AtServer
Function RouteStringByLinkKey(ConnectionKey)
	Return Object.Route.FindRows(New Structure("ConnectionKey",ConnectionKey))[0];
EndFunction

&AtServer
Function FillBySpendingOrdersOnServer()
	
	HasChanges = GoodsDelivery.ReCompleteTransportTaskForExpenseOrders(Object, GoodsToDeliver);
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	UpgradeLoadingDepots();
	FillInServiceDetailsOfRoute();
	Return HasChanges;
	
EndFunction

&AtServer
Procedure ConfigureByArtistType()
	
	PerformedByCarrier = Object.JobIsPerformedBy = Enums.TypesOfTransportationJobAssignees.Carrier;
	
	Items.Carrier.Visible             = PerformedByCarrier;
	Items.Driver.Visible               = Not PerformedByCarrier;
	Items.CourierShippingAgent.Visible       = Not PerformedByCarrier;
	Items.InformationAboutTheSender.Visible = PerformedByCarrier
												And Object.Operation = Enums.DeliveryKinds.FromWarehouse;
	
	If PerformedByCarrier
		And ValueIsFilled(Object.Carrier) Then
		
		If Not ValueIsFilled(Object.Counterparty) Then
			FillInCounterpartyAndCarrierSBankAccount();
		EndIf;
		
	Else
		Object.Carrier = Catalogs.Partners.EmptyRef();
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		Object.CarrierBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
		
		Carrier = Object.Carrier;
	EndIf;
	
	FillItsDriverSelectionLists();
	
EndProcedure

&AtServer
Procedure CarrierWhenChangedOnServer()
	
	If Carrier <> Object.Carrier Then
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		Object.CarrierBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
		
		FillItsDriverSelectionLists();		
		
	EndIf;
	
	If ValueIsFilled(Object.Carrier) Then
		FillInCounterpartyAndCarrierSBankAccount();
	Else
		Object.Carrier = Catalogs.Partners.EmptyRef();
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		Object.CarrierBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
	EndIf;
	
	Carrier = Object.Carrier;
	
EndProcedure

&AtServer
Procedure DriverWhenChangingOnServer()
	
	TTNParameters = New Structure;
	TTNParameters.Insert("DriverFullName");
	TTNParameters.Insert("CertificateSeries");
	TTNParameters.Insert("CertificateNumber");
	
	If ValueIsFilled(Object.Vehicle_) Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Persons.Description AS DriverFullName,
		|	DocumentsPersons.Series AS CertificateSeries,
		|	DocumentsPersons.Number AS CertificateNumber
		|FROM
		|	Catalog.Persons AS Persons
		|		LEFT JOIN InformationRegister.DocumentsPersons.SliceLast AS DocumentsPersons
		|		ON Persons.Ref = DocumentsPersons.Person
		|			AND (DocumentsPersons.DocumentKind = VALUE(Catalog.DocumentKindsOfPersons.DriverLicense))
		|WHERE
		|	Persons.Ref = &Ref";
		
		Query.SetParameter("Ref", Object.Driver);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			FillPropertyValues(TTNParameters, Selection);
		EndIf;			
	EndIf;
	
	FillPropertyValues(Object, TTNParameters);

EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()
	Object.CarrierBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty);
EndProcedure

&AtClient
Procedure RouteAdditionalInformationStartChoiceCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		CurrentData = Items.Route.CurrentData;
		CurrentData.AdditionalInformation = ClosingResult;
	EndIf; 
	
EndProcedure

&AtClient
Procedure AfterEditingOrders(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	Modified = True;
	AfterEditingOrdersServer(Result);
	
EndProcedure

&AtServer
Procedure AfterEditingOrdersServer(Result)
	
	QueryText =
	"SELECT
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Warehouse,
	|	GoodsToDeliver.RecipientSender,
	|	GoodsToDeliver.Products,
	|	GoodsToDeliver.Characteristic,
	|	GoodsToDeliver.Purpose,
	|	GoodsToDeliver.Series,
	|	GoodsToDeliver.Count,
	|	GoodsToDeliver.AllGoods
	|INTO GoodsToDeliver
	|FROM
	|	&GoodsToDeliver AS GoodsToDeliver
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Warehouse,
	|	GoodsToDeliver.RecipientSender,
	|	GoodsToDeliver.Products,
	|	GoodsToDeliver.Characteristic,
	|	GoodsToDeliver.Purpose,
	|	GoodsToDeliver.Series,
	|	GoodsToDeliver.Count,
	|	GoodsToDeliver.AllGoods
	|INTO GoodsForDeliveryEdited
	|FROM
	|	&GoodsForDeliveryEdited AS GoodsToDeliver
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ConnectionKey,
	|	References.ReferenceOrder,
	|	References.Weight,
	|	References.VolumeM3,
	|	References.Carrier,
	|	References.RecipientSender,
	|	References.TimeFrom,
	|	References.TimeTo,
	|	References.AdditionalInformation,
	|	References.Delivered,
	|	References.Warehouse,
	|	References.DeliveredInFull
	|INTO References
	|FROM
	|	&References AS References
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ConnectionKey,
	|	References.ReferenceOrder,
	|	References.Weight,
	|	References.VolumeM3,
	|	References.Carrier,
	|	References.RecipientSender,
	|	References.TimeFrom,
	|	References.TimeTo,
	|	References.AdditionalInformation,
	|	References.Delivered,
	|	References.Warehouse,
	|	References.DeliveredInFull
	|INTO OrdersEdited
	|FROM
	|	&OrdersEdited AS References
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersEdited.ConnectionKey,
	|	OrdersEdited.ReferenceOrder,
	|	OrdersEdited.Carrier,
	|	OrdersEdited.RecipientSender,
	|	OrdersEdited.TimeFrom,
	|	OrdersEdited.TimeTo,
	|	OrdersEdited.AdditionalInformation,
	|	OrdersEdited.Warehouse,
	|	OrdersEdited.Weight AS Weight,
	|	OrdersEdited.VolumeM3 AS VolumeM3,
	|	OrdersEdited.Delivered AS Delivered,
	|	OrdersEdited.DeliveredInFull AS DeliveredInFull
	|INTO DispositionsResult
	|FROM
	|	OrdersEdited AS OrdersEdited
	|
	|UNION ALL
	|
	|SELECT
	|	References.ConnectionKey,
	|	References.ReferenceOrder,
	|	References.Carrier,
	|	References.RecipientSender,
	|	References.TimeFrom,
	|	References.TimeTo,
	|	References.AdditionalInformation,
	|	References.Warehouse,
	|	References.Weight,
	|	References.VolumeM3,
	|	References.Delivered,
	|	References.DeliveredInFull
	|FROM
	|	References AS References
	|WHERE
	|	References.ConnectionKey <> &ConnectionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemoteOrders.ReferenceOrder
	|FROM
	|	(SELECT DISTINCT
	|		References.ReferenceOrder AS ReferenceOrder,
	|		1 AS CollapseField
	|	FROM
	|		References AS References
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		DispositionsResult.ReferenceOrder,
	|		-1
	|	FROM
	|		DispositionsResult AS DispositionsResult) AS RemoteOrders
	|
	|GROUP BY
	|	RemoteOrders.ReferenceOrder
	|
	|HAVING
	|	SUM(RemoteOrders.CollapseField) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DispositionsResult.ConnectionKey,
	|	DispositionsResult.ReferenceOrder,
	|	DispositionsResult.Carrier,
	|	DispositionsResult.RecipientSender,
	|	DispositionsResult.TimeFrom,
	|	DispositionsResult.TimeTo,
	|	DispositionsResult.AdditionalInformation,
	|	DispositionsResult.Warehouse,
	|	DispositionsResult.Weight,
	|	DispositionsResult.VolumeM3,
	|	DispositionsResult.Delivered,
	|	DispositionsResult.DeliveredInFull
	|FROM
	|	DispositionsResult AS DispositionsResult
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(OrdersEdited.Weight) AS Weight,
	|	SUM(OrdersEdited.VolumeM3) AS VolumeM3,
	|	MIN(OrdersEdited.Delivered) AS Delivered,
	|	COUNT(*) AS NumberOfReferences
	|FROM
	|	OrdersEdited AS OrdersEdited
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Warehouse,
	|	GoodsToDeliver.RecipientSender,
	|	GoodsToDeliver.Products,
	|	GoodsToDeliver.Characteristic,
	|	GoodsToDeliver.Purpose,
	|	GoodsToDeliver.Series,
	|	GoodsToDeliver.Count,
	|	GoodsToDeliver.AllGoods
	|FROM
	|	GoodsToDeliver AS GoodsToDeliver
	|		INNER JOIN References AS References
	|		ON (References.ReferenceOrder = GoodsToDeliver.ReferenceOrder)
	|			AND (References.Warehouse = GoodsToDeliver.Warehouse)
	|WHERE
	|	References.ConnectionKey <> &ConnectionKey
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForDeliveryEdited.ReferenceOrder,
	|	GoodsForDeliveryEdited.Warehouse,
	|	GoodsForDeliveryEdited.RecipientSender,
	|	GoodsForDeliveryEdited.Products,
	|	GoodsForDeliveryEdited.Characteristic,
	|	GoodsForDeliveryEdited.Purpose,
	|	GoodsForDeliveryEdited.Series,
	|	GoodsForDeliveryEdited.Count,
	|	GoodsForDeliveryEdited.AllGoods
	|FROM
	|	GoodsForDeliveryEdited AS GoodsForDeliveryEdited";
	
	Query = New Query(QueryText);
	
	LineItem = Object.Route.FindByID(Items.Route.CurrentRow);
	
	Query.SetParameter("OrdersEdited", GetFromTempStorage(Result.ReferenceAddress));
	Query.SetParameter("GoodsForDeliveryEdited", GetFromTempStorage(Result.AddressOfGoodsForDelivery));
	Query.SetParameter("GoodsToDeliver", GoodsToDeliver.Unload());
	Query.SetParameter("References", Object.References.Unload());
	Query.SetParameter("ConnectionKey", LineItem.ConnectionKey);
	
	QueryResult = Query.ExecuteBatch();
	
	UBound = QueryResult.UBound();
	
	Selection = QueryResult[UBound-1].Select();
	Selection.Next();
	If Selection.NumberOfReferences = 0 Then
		Object.Route.Delete(LineItem);
	Else
		FillPropertyValues(LineItem,Selection);
	EndIf;
	
	Object.References.Load(QueryResult[UBound-2].Unload());
		
	GoodsToDeliver.Load(QueryResult[UBound].Unload());
	GoodsDelivery.ThisAttributeIsDeliveredInFull(GoodsToDeliver.Unload(), Object.References);
	
	FillInServiceDetailsOfRoute();
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	UpgradeLoadingDepots();
	
EndProcedure

&AtServer
Procedure FillGoodsForDelivery()
	RecordSet = InformationRegisters.GoodsToDeliver.CreateRecordSet();
	RecordSet.Filter.TransportationJob.Set(Object.Ref);
	RecordSet.Read();
	GoodsToDeliver.Load(RecordSet.Unload());
EndProcedure	

&AtServer
Procedure FillInCounterpartyAndCarrierSBankAccount()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Carrier, Object.Counterparty);
	
	If ValueIsFilled(Object.Counterparty) Then
		Object.CarrierBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
			Object.Counterparty);
	EndIf;
	
EndProcedure

&AtServer
Function CheckTaskBlocking()
	
	If Object.Ref.IsEmpty() Then
		
		Return True;
		
	Else
		
		Try
			
			DocObject = Object.Ref.GetObject();
			LockFormDataForEdit();
			Return True;
			
		Except
			
			Text = NStr("vi = 'Không thể chặn %Job% cho các thay đổi.';
						|ru = 'Не удалось заблокировать %Job% для изменений.';
						|en = 'Cannot lock %Job% for editing.'; fa = 'Cannot lock %Job% for editing.';
						|it = 'Impossibile bloccare %Job% per le modifiche.';
						|pl = 'Nie udało się zablokować %Job% do zmian.';
						|tr = '%Job% değişimi engellenemedi.'");
			Text = StrReplace(Text,"%Job%", String(Object.Ref));
			Common.MessageToUser(Text, Object.Ref);
			Return False;
			
		EndTry;
		
	EndIf;
	
EndFunction

&AtServer
Procedure FillItsDriverSelectionLists()
	
	Items.DriverFullName.ChoiceList.Clear();
	Items.VehicleRegPlate.ChoiceList.Clear();
	Items.VehicleType.ChoiceList.Clear();
	
	If Not (Object.JobIsPerformedBy = Enums.TypesOfTransportationJobAssignees.Carrier
		And Object.Operation = Enums.DeliveryKinds.FromWarehouse
		And ValueIsFilled(Object.Carrier)) Then
		Return;
	EndIf;
	
	#Region DriverFullName
	
	Query =  New Query;
	Query.Text = 
	"SELECT TOP 50
	|	TransportationJob.DriverFullName AS Driver,
	|	TransportationJob.CertificateNumber AS CertificateNumber,
	|	TransportationJob.CertificateSeries AS CertificateSeries,
	|	MAX(TransportationJob.Date) AS Date
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|WHERE
	|	TransportationJob.Carrier = &Carrier
	|	AND TransportationJob.DriverFullName <> """"
	|
	|GROUP BY
	|	TransportationJob.DriverFullName,
	|	TransportationJob.CertificateSeries,
	|	TransportationJob.CertificateNumber
	|
	|ORDER BY
	|	MAX(TransportationJob.Date) DESC";
	
	Query.SetParameter("Carrier", Object.Carrier);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While QueryResult.Next() Do
		DriverInformation = New Structure("Driver, CertificateSeries, CertificateNumber");
		FillPropertyValues(DriverInformation, QueryResult);
		Items.DriverFullName.ChoiceList.Add(DriverInformation, QueryResult.Driver);
	EndDo;	
	
	#EndRegion
	
	#Region VehicleRegPlate
	
	Query =  New Query;
	Query.Text = 
	"SELECT TOP 50
	|	TransportationJob.VehicleModel AS VehicleModel,
	|	TransportationJob.VehicleRegPlate AS VehicleRegPlate,
	|	TransportationJob.LicenseCardKind AS LicenseCardKind,
	|	TransportationJob.LicenseCardNumber AS LicenseCardNumber,
	|	TransportationJob.RegistrationNumberOfLicenseCard AS RegistrationNumberOfLicenseCard,
	|	TransportationJob.LicenseCardSeries AS LicenseCardSeries,
	|	TransportationJob.Trailer AS Trailer,
	|	TransportationJob.TrailerRegPlate AS TrailerRegPlate,
	|	TransportationJob.TransportationType AS TransportationType,
	|	MAX(TransportationJob.Date) AS Date,
	|	TransportationJob.VehicleCarryingCapacityInTons AS VehicleCarryingCapacityInTons,
	|	TransportationJob.VehicleCubicMetresCapacity AS VehicleCubicMetresCapacity,
	|	TransportationJob.VehicleType AS VehicleType
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|WHERE
	|	TransportationJob.Carrier = &Carrier
	|	AND TransportationJob.VehicleRegPlate <> """"
	|
	|GROUP BY
	|	TransportationJob.VehicleModel,
	|	TransportationJob.VehicleRegPlate,
	|	TransportationJob.LicenseCardKind,
	|	TransportationJob.LicenseCardNumber,
	|	TransportationJob.RegistrationNumberOfLicenseCard,
	|	TransportationJob.LicenseCardSeries,
	|	TransportationJob.Trailer,
	|	TransportationJob.TrailerRegPlate,
	|	TransportationJob.TransportationType,
	|	TransportationJob.VehicleCarryingCapacityInTons,
	|	TransportationJob.VehicleCubicMetresCapacity,
	|	TransportationJob.VehicleType
	|
	|ORDER BY
	|	MAX(TransportationJob.Date) DESC";
	
	Query.SetParameter("Carrier", Object.Carrier);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Items.VehicleRegPlate.ChoiceList.Clear();
	
	While QueryResult.Next() Do
		VehicleInformation = New Structure("VehicleRegPlate, VehicleModel, VehicleType, VehicleCarryingCapacityInTons, VehicleCubicMetresCapacity, LicenseCardKind, LicenseCardNumber, RegistrationNumberOfLicenseCard, LicenseCardSeries, Trailer, TrailerRegPlate, TransportationType");
		FillPropertyValues(VehicleInformation, QueryResult);
		Items.VehicleRegPlate.ChoiceList.Add(VehicleInformation, QueryResult.VehicleRegPlate);
	EndDo;
	
	#EndRegion
	
	#Region VehicleType
	
	Query =  New Query;
	Query.Text = 
	"SELECT TOP 50
	|	MAX(TransportationJob.Date) AS Date,
	|	TransportationJob.VehicleCarryingCapacityInTons AS VehicleCarryingCapacityInTons,
	|	TransportationJob.VehicleCubicMetresCapacity AS VehicleCubicMetresCapacity,
	|	TransportationJob.VehicleType AS VehicleType
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|WHERE
	|	TransportationJob.Carrier = &Carrier
	|	AND TransportationJob.VehicleRegPlate = """"
	|	AND TransportationJob.VehicleType <> """"
	|
	|GROUP BY
	|	TransportationJob.VehicleCarryingCapacityInTons,
	|	TransportationJob.VehicleCubicMetresCapacity,
	|	TransportationJob.VehicleType
	|
	|ORDER BY
	|	MAX(TransportationJob.Date) DESC";
	
	Query.SetParameter("Carrier", Object.Carrier);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Items.VehicleType.ChoiceList.Clear();
	
	While QueryResult.Next() Do
		VehicleInformation = New Structure("VehicleType, VehicleCarryingCapacityInTons, VehicleCubicMetresCapacity");
		FillPropertyValues(VehicleInformation, QueryResult);
		Items.VehicleType.ChoiceList.Add(VehicleInformation, QueryResult.VehicleType);
	EndDo;     
	
	#EndRegion

EndProcedure

&AtClient
Procedure VehicleLoadCapacityCapacityWhenChanging()
	
	CarryingCapacityInUserUnit = Object.VehicleCarryingCapacityInTons / TonConversionFactor;
	CapacityInUserUnits = Object.VehicleCubicMetresCapacity / CubicMeterConversionFactor;
	DisplayUserNameOnServer(ThisObject);
	UpdateTotalWeightVolumeOccupancy(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayUserNameOnServer(Form)
	
	Form.Items.DecorationUnitOfVolumeMeasurement.Title = StrTemplate(NStr("vi = '(%1 %2)';
																			|ru = '(%1 %2)';
																			|en = '(%1 %2)'; fa = '(%1 %2)';
																			|it = '(%1 %2)';
																			|pl = '(%1 %2)';
																			|tr = '(%1 %2)'"), 
		Form.CapacityInUserUnits,
		String(Form.UnitOfMeasureForVolume));
		
	Form.Items.DecorationUnitOfWeight.Title = StrTemplate(NStr("vi = '(%1 %2)';
																|ru = '(%1 %2)';
																|en = '(%1 %2)'; fa = '(%1 %2)';
																|it = '(%1 %2)';
																|pl = '(%1 %2)';
																|tr = '(%1 %2)'"), 
		Form.CarryingCapacityInUserUnit,
		String(Form.UnitOfMeasureForWeight));
	
EndProcedure

#EndRegion

#Region Localization

#Region ConsignmentNote


#EndRegion

&AtClient
Procedure RouteSelectionLocalization(Item, RowSelected, Field, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfRouteLocalization(TempTablesManager)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServerLocalization()
	
	
	Return;
	
EndProcedure

&AtClient
Procedure NotificationProcessingLocalization(EventName, Parameter, Source);
	
	
	Return;
	
EndProcedure


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
