
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisObject);
	
	List.Parameters.SetParameterValue("AllowSelectionOfInvalid", Parameters.AllowSelectionOfInvalid);
	List.Parameters.SetParameterValue("Partner",                     Parameters.Partner);
	List.Parameters.SetParameterValue("OnlyUsedBySalesRepresentative", Parameters.OnlyUsedBySalesRepresentative);
	List.Parameters.SetParameterValue("DocumentDate",               ?(ValueIsFilled(Parameters.DocumentDate), BegOfDay(Parameters.DocumentDate), BegOfDay(CurrentSessionDate())));
	
	If Not Parameters.OnlyStandard Then
		Partner = Parameters.Partner;
	EndIf;

	UseTheBusinessNetworkExchange	= False;
	
	UseTransferToCustodyWithRightOfSale	= GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	UseSalesCommission								= GetFunctionalOption("UseSalesCommission");
	ToUseTermsOfSales							= GetFunctionalOption("ToUseTermsOfSales");
	UseShipmentWithDeferredTransferOfTitle =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
	
	If UseTheBusinessNetworkExchange And Not ToUseTermsOfSales Then
		Items.GroupCommentToUseTermsOfSales.Visible = True;
	Else
		Items.GroupCommentToUseTermsOfSales.Visible = False;
	EndIf;
	
	If Parameters.Property("OnlyTransferOperations")
		And ValueIsFilled(Parameters.OnlyTransferOperations)
		And Parameters.OnlyTransferOperations Then
		
		If UseTransferToCustodyWithRightOfSale
			Or UseSalesCommission
			Or UseShipmentWithDeferredTransferOfTitle Then
			
			FilterGroup = CommonClientServer.CreateFilterItemGroup(
							List.Filter.Items,
							"OnlyTransferOperations",
							DataCompositionFilterItemsGroupType.OrGroup);
			
		EndIf;
		
		If UseTransferToCustodyWithRightOfSale Then
			ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
		EndIf;
		
		If UseSalesCommission Then
			CommissionSelectionGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
			CommissionSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.BusinessTransactions.TransferToCommissionAgent;
			
			ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("ConsignmentSales25");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
		EndIf;
		
		TransferShipmentOperations = Undefined;
		If UseShipmentWithDeferredTransferOfTitle
			And Parameters.Property("TransferShipmentOperations", TransferShipmentOperations)
			And TransferShipmentOperations = True Then
			
			ShipmentTransferSelectionGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
			ShipmentTransferSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			CommonClientServer.AddCompositionItem(ShipmentTransferSelectionGroup,
				"SaleWithDeferredTransferOfTitleIsAllowed",
				DataCompositionComparisonType.Equal,
				True);
				
			CommonClientServer.AddCompositionItem(ShipmentTransferSelectionGroup,
				"ContractsAreUsed",
				DataCompositionComparisonType.Equal,
				True);
		EndIf;
	EndIf;
	
	If Not Parameters.OnlyTransferOperations
		And ValueIsFilled(Parameters.BusinessOperation) Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"BusinessOperation",
			Parameters.BusinessOperation,
			DataCompositionComparisonType.Equal,
			,
			True);
		
		BusinessOperation = Parameters.BusinessOperation;
		
	EndIf;
	
	If Parameters.Property("ConsignmentSales25")
		And ValueIsFilled(Parameters.ConsignmentSales25)
		And UseSalesCommission Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"ConsignmentSales25",
			Parameters.ConsignmentSales25,
			DataCompositionComparisonType.Equal,
			,
			True);
		
	EndIf;
	
	ShipmentWithDeferredTransferOfTitle25 = Undefined;
	
	If UseShipmentWithDeferredTransferOfTitle
		And Parameters.Property("ShipmentWithDeferredTransferOfTitle25", ShipmentWithDeferredTransferOfTitle25)
		And ValueIsFilled(ShipmentWithDeferredTransferOfTitle25) Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"SaleWithDeferredTransferOfTitleIsAllowed",
			ShipmentWithDeferredTransferOfTitle25,
			DataCompositionComparisonType.Equal,
			,
			True);
		
	EndIf;
	
	If Parameters.Property("ContractsAreUsed")
		And Parameters.ContractsAreUsed <> Undefined Then
		
		CommonClientServer.SetDynamicListFilterItem(List,
			"ContractsAreUsed",
			Parameters.ContractsAreUsed,
			DataCompositionComparisonType.Equal,
			,
			True);
		
	EndIf;
	
	If Parameters.Filter.Property("Organization")
		And ValueIsFilled(Parameters.Filter.Organization) Then
		
		Organization = Parameters.Filter.Organization;
		SetSelectionByOrganization(ThisObject);
		Parameters.Filter.Delete("Organization");
		
	EndIf;
	
	TextStandart = NStr("vi = 'Chung';
						|ru = 'Типовое';
						|en = 'Standard'; fa = 'استاندارد';
						|it = 'Accordo tipo';
						|pl = 'Typowa';
						|tr = 'Standart'");
	TextIndividual = NStr("vi = 'Riêng';
							|ru = 'Индивидуальное';
							|en = 'Special'; fa = 'ویژه';
							|it = 'Accordi individuali';
							|pl = 'Indywidualna';
							|tr = 'Özelleştirilmiş'");
	
	Items.AgreementType.ChoiceList.Add("", NStr("vi = 'Tất cả';
												|ru = 'Все';
												|en = 'All'; fa = 'همه';
												|it = 'Tutti';
												|pl = 'All';
												|tr = 'Tümü'"));
	Items.AgreementType.ChoiceList.Add(TextStandart, NStr("vi = 'Chung';
															|ru = 'Типовые';
															|en = 'Standard'; fa = 'استاندارد';
															|it = 'Di tipo';
															|pl = 'Wzory';
															|tr = 'Standartlar'"));
	Items.AgreementType.ChoiceList.Add(TextIndividual, NStr("vi = 'Riêng';
															|ru = 'Индивидуальные';
															|en = 'Special'; fa = 'ویژه';
															|it = 'Individuali';
															|pl = 'Indywidualne';
															|tr = 'Özelleştirilmişler'"));
	
	// Redefining the output types of agreements and setting the properties of dependent elements.
	UseStandardTermsOfSalesWithCustomers			= GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales	= GetFunctionalOption("UseCustomerTermsOfSales");
	
	OnlyStandard = UseStandardTermsOfSalesWithCustomers
					And Not UseCustomerTermsOfSales;
	OnlyPersonal = Not UseStandardTermsOfSalesWithCustomers
							And UseCustomerTermsOfSales;
	
	If OnlyStandard
		Or (Parameters.OnlyStandard
			And Not OnlyPersonal) Then
		
		AgreementType = TextStandart;
		Parameters.OnlyStandard = True;
		OnlyStandard = True;
		
		Title = NStr("vi = 'Thỏa thuận chung với khách hàng';
					|ru = 'Типовые соглашения с клиентами';
					|en = 'Standard terms of sales'; fa = 'شرایط استاندارد فروش';
					|it = 'Contratti tipo con i clienti';
					|pl = 'Typowe umowy z klientami';
					|tr = 'Standart satış koşulları'");
		TMCommonUseClientServer.SetFormItemProperty(Items, "AgreementType", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListAgreementType", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "CreateIndividualAgreementList", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuCreateIndividualAgreement", "Visible", False);
		
	ElsIf OnlyPersonal Then
		AgreementType = TextIndividual;
		
		Title = NStr("vi = 'Thỏa thuận riêng với khách hàng';
					|ru = 'Индивидуальные соглашения с клиентами';
					|en = 'Special terms of sales'; fa = 'شرایط ویژه فروش';
					|it = 'Accordi personali con i clienti';
					|pl = 'Indywidualne umowy z klientami';
					|tr = 'Özelleştirilmiş satış koşulları'");
		TMCommonUseClientServer.SetFormItemProperty(Items, "AgreementType", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListAgreementType", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListCreateStandardAgreement", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuCreateStandardAgreement", "Visible", False);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List,"OnlyStandard", OnlyStandard);
	CommonClientServer.SetDynamicListParameter(List,"OnlyPersonal", OnlyPersonal);
	
	CommonClientServer.SetDynamicListParameter(List,"Standard_", TextStandart);
	CommonClientServer.SetDynamicListParameter(List,"Individual_3", TextIndividual);
	CommonClientServer.SetDynamicListParameter(
		List, "NotApproved", NStr("vi = 'Không thống nhất';
									|ru = 'Не согласовано';
									|en = 'Not approved'; fa = 'تأییدنشده';
									|it = 'Не согласовано';
									|pl = 'Nie uzgodniono';
									|tr = 'Onaylanmadı'"));
	CommonClientServer.SetDynamicListParameter(List,"Valid", NStr("vi = 'Có hiệu lực';
																	|ru = 'Действует';
																	|en = 'Valid'; fa = 'معتبر';
																	|it = 'In vigore';
																	|pl = 'Aktualne';
																	|tr = 'Aktif'"));
	CommonClientServer.SetDynamicListParameter(
		List, "Closed", NStr("vi = 'Đã đóng';
							|ru = 'Закрыто';
							|en = 'Closed'; fa = 'بسته‌شده';
							|it = 'Закрыто';
							|pl = 'Zamknięte';
							|tr = 'Kapalı'"));
	
	If Parameters.OnlyStandard Then
		Title = NStr("vi = 'Thỏa thuận chung với khách hàng';
					|ru = 'Типовые соглашения с клиентами';
					|en = 'Standard terms of sales'; fa = 'شرایط استاندارد فروش';
					|it = 'Contratti tipo con i clienti';
					|pl = 'Typowe umowy z klientami';
					|tr = 'Standart satış koşulları'");
		TMCommonUseClientServer.SetFormItemProperty(Items, "AgreementType", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListAgreementType", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "CreateIndividualAgreementList", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuCreateIndividualAgreement", "Visible", False);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListCreateStandardAgreement", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuCreateStandardAgreement", "Visible", False);
	EndIf;
	
	If Not AccessRight("Insert",Metadata.Catalogs.TermsOfSale) Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListCreateStandardAgreement", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "CreateIndividualAgreementList", "Visible", False);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"PartnerSelection_",
		Parameters.Partner,
		DataCompositionComparisonType.Equal,
		,
		True);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Not UserRightsCached.ModificationOfModelAgreements() Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListCreateStandardAgreement", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuCreateStandardAgreement", "Visible", False);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");

EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Manager      = Settings.Get("Manager");
	AgreementType = Settings.Get("AgreementType");
	If Not ValueIsFilled(Organization) Then
		
		Organization = Settings.Get("Organization");
		SetSelectionByOrganization(ThisObject);
		
	Else
		Settings.Delete("Organization");
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
	If Not Parameters.OnlyStandard Then
		CommonClientServer.SetDynamicListFilterItem(List, "AgreementType", AgreementType, DataCompositionComparisonType.Equal,, ValueIsFilled(AgreementType));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AgreementTypeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "AgreementType", AgreementType, DataCompositionComparisonType.Equal,, ValueIsFilled(AgreementType));
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	SetSelectionByOrganization(ThisObject);
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FillingValues = New Structure;
	FillingValues.Insert("Standard_", Parameters.OnlyStandard);
	FillingValues.Insert("Organization", Organization);
	FillingValues.Insert("Partner", Partner);
	FillingValues.Insert("BusinessOperation", BusinessOperation);
	
	FormParameters = New Structure;
	FormParameters.Insert("Standard_", Parameters.OnlyStandard);
	FormParameters.Insert("FillingValues", FillingValues);
	
	OpenForm(
		"Catalog.TermsOfSale.ObjectForm",
		FormParameters,
		,
		,);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateStandardAgreement(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Standard_", True);
	FormParameters.Insert("FillingValues", New Structure("Standard_,Organization", True, Organization));

	OpenForm(
		"Catalog.TermsOfSale.ObjectForm",
		FormParameters,
		,
		,);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region Other

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Catalog.TermsOfSale.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByOrganization(Form)
	
	CompanyArray = New Array();
	CompanyArray.Add(Form.Organization);
	CompanyArray.Add(PredefinedValue("Catalog.Companies.EmptyRef"));
	
	CommonClientServer.SetDynamicListFilterItem(Form.List,
	                                                                        "Organization", 
	                                                                        CompanyArray, 
	                                                                        DataCompositionComparisonType.InList
	                                                                        ,,
	                                                                        ValueIsFilled(Form.Organization));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion
