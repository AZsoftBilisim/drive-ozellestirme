#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Catalogs.CounterpartyContracts.AddGenerateCommand(GenerationCommands);
	Catalogs.IntercompanyContracts.AddGenerateCommand(GenerationCommands);
	Catalogs.ContactPersonsForPartners.AddGenerateCommand(GenerationCommands);
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	Catalogs.SalesOpportunitiesToCustomer.AddGenerateCommand(GenerationCommands);
	
	UseCustomerTermsOfSales = GetFunctionalOption("UseCustomerTermsOfSales");
	If UseCustomerTermsOfSales Then
		Catalogs.TermsOfSale.AddGenerateCommand(GenerationCommands);
	EndIf;
	
	Catalogs.TermsOfPurchaseFromVendors.AddGenerateCommand(GenerationCommands);
	
	Command = Documents.SalesOrder.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	Command = Documents.PurchaseOrder.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	Command = Documents.RequestForReturnOfGoodsFromCustomer.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	Command = Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	Command = Documents.VendorPriceList.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	
	Command = Documents.MaterialProviderOrder2_5.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	PartnersAndCounterpartiesLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	#Region OurEnterprise
	Item = Items.Add();
	Item.Code = "00-00000001";
	Item.PredefinedDataName = "OurEnterprise";
	Item.Description = NStr("vi = 'Doanh nghiệp chúng ta';
							|ru = 'Наше предприятие';
							|en = 'Our enterprise'; fa = 'سازمان ما';
							|it = 'La nostra impresa';
							|pl = 'Nasze przedsiębiorstwo';
							|tr = 'İşletmemiz'", DefaultLanguageCode);
	Item.DescriptionFull = NStr("vi = 'Doanh nghiệp chúng ta';
								|ru = 'Наше предприятие';
								|en = 'Our enterprise'; fa = 'سازمان ما';
								|it = 'La nostra impresa';
								|pl = 'Nasze przedsiębiorstwo';
								|tr = 'İşletmemiz'", DefaultLanguageCode);
	Item.LegalEntityIndividual = Enums.IndividualCompany.Company;
	Item.RegistrationDate = Date("19800101000000");
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		LinkOurEnterprise = Catalogs.Partners.OurEnterprise;
		ArrayOfPartners = PartnersAndCounterparties.GetAllPartnersOfPartner(LinkOurEnterprise);
		If ArrayOfPartners.Count() = 0 Then
			Counterparty = Catalogs.Counterparties.CreateItem();
			Counterparty.Description = Item.Description;
			Counterparty.DescriptionFull = Item.DescriptionFull;
			Counterparty.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity;
			Counterparty.Partner = LinkOurEnterprise;
			Counterparty.Write();
		EndIf;
	EndIf;
	#EndRegion

	#Region UnknownPartner
	Item = Items.Add();
	Item.Code = "00-00000002";
	Item.PredefinedDataName = "UnknownPartner";
	Item.Description = NStr("vi = 'Bạn hàng chưa xác định';
							|ru = 'Неизвестный партнер';
							|en = 'Unknown partner'; fa = 'Unknown partner';
							|it = 'Partner sconosciuto';
							|pl = 'Nieznany partner';
							|tr = 'Bilinmeyen iş ortağı'", DefaultLanguageCode);
	Item.DescriptionFull = NStr("vi = 'Bạn hàng chưa xác định';
								|ru = 'Неизвестный партнер';
								|en = 'Unknown partner'; fa = 'Unknown partner';
								|it = 'Partner sconosciuto';
								|pl = 'Nieznany partner';
								|tr = 'Bilinmeyen iş ortağı'", DefaultLanguageCode);
	Item.LegalEntityIndividual = Enums.IndividualCompany.Company;
	Item.RegistrationDate = Date("19800101000000");
	Item.Client = True;
	Item.Vendor = True;
	Item.OtherRelations = True;
	#EndRegion

	#Region RetailCustomer
	Item = Items.Add();
	Item.Code = "00-00000003";
	Item.PredefinedDataName = "RetailCustomer";
	Item.Description = NStr("vi = 'Khách lẻ';
							|ru = 'Розничный покупатель';
							|en = 'Retail customer'; fa = 'Retail customer';
							|it = 'Compratore al dettaglio';
							|pl = 'Klient detaliczny';
							|tr = 'Perakende müşteri'", DefaultLanguageCode);
	Item.DescriptionFull = NStr("vi = 'Khách lẻ';
								|ru = 'Розничный покупатель';
								|en = 'Retail customer'; fa = 'Retail customer';
								|it = 'Compratore al dettaglio';
								|pl = 'Klient detaliczny';
								|tr = 'Perakende müşteri'", DefaultLanguageCode);
	Item.LegalEntityIndividual = Enums.IndividualCompany.Person_;
	Item.RegistrationDate = Date("19800101000000");
	Item.Client = True;
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.Partners - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

// Checks the possibility and sets an individual price list for the object.
// 
// Parameters:
// 	Ref - CatalogRef.Partners - Link to the price list column.
// 	PricesKind - CatalogRef.TypesOfPrices - Link to the price list column.
// Returns:
// 	Boolean - The result of the execution.
Function InstallIPL(Ref, PricesKind) Export
	OperationResult = False;
	
	CatalogObject = Ref.GetObject();
	If ValueIsFilled(CatalogObject.SpecialPriceType) Then
		OperationResult = False;
		
		MessageTextTemplate = NStr("vi = 'Chưa thiết lập dạng giá riêng cho bạn hàng ""%ObjectName_1%"" do nguyên nhân: %Cause%';
									|ru = 'Не произведена установка индивидуального виды цен для партнера ""%ObjectName_1%"" по причине: %Cause%';
									|en = 'The individual price types have not been set for the partner ""%ObjectName_1%"". Reason: %Cause%'; fa = 'The individual price types have not been set for the partner ""%ObjectName_1%"". Reason: %Cause%';
									|it = 'Non è stata eseguita l''impostazione dei tipi di prezzo individuale per partner ""%ObjectName_1%"" a causa di: %Cause%';
									|pl = 'Nie wykonano ustawienia indywidualnego rodzaju cen dla partnera ""%ObjectName_1%"" z powodu: %Cause%';
									|tr = '""%ObjectName_1%"" iş ortağı için özelleştirilmiş fiyat türünün yapılandırılamama nedeni: %Cause%'");
		MessageText = StrReplace(MessageTextTemplate, "%ObjectName_1%", CatalogObject.Description);
		MessageText = StrReplace(MessageText, "%Cause%", "u partner_ already is_specified individual_ kind prices_!");
		
		Raise MessageText;
	Else	
		CatalogObject.SpecialPriceType = PricesKind;
		SetPrivilegedMode(True);
		CatalogObject.Write();
		SetPrivilegedMode(False);
		OperationResult = True;
	EndIf;
	
	Return OperationResult;
EndFunction

// Deletes the individual price list for the item.
// 
// Parameters:
// 	Ref - CatalogRef.Partners - Link to the price list column.
// Returns:
// 	Boolean - The result of the execution.
Function DeleteIPL(Ref) Export
	OperationResult = False;	
	
		
	CatalogObject = Ref.GetObject();
	CatalogObject.SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
	SetPrivilegedMode(True);
	CatalogObject.Write();
	SetPrivilegedMode(False);
	
	
	OperationResult = True;
	
	Return OperationResult;
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Ref)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Ref
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Ref
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.ImportDataFromFile

// Sets parameters for loading data from a file
//
// Parameters:
//     Parameters - Structure - List of parameters. Fields: 
//         * Title           - String       - The window title 
//         * RequiredColumns2 - Array       - A list of the names of the columns are mandatory
//         * ColumnDataType    - Map - Description of the data type
//
Procedure DefineParametersForLoadingDataFromFile(Parameters) Export
	
	Parameters.Title = NStr("vi = 'Đối tác';
							|ru = 'Контрагенты';
							|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
							|it = 'Controparti';
							|pl = 'Counterparties';
							|tr = 'Cari hesaplar'");
	
	Parameters.ColumnDataType.Insert("WorkName",                   New TypeDescription("String",, New StringQualifiers(100)));
	Parameters.ColumnDataType.Insert("PublicName",                 New TypeDescription("String",, New StringQualifiers(250)));
	Parameters.ColumnDataType.Insert("DescriptionInternational",             New TypeDescription("String",, New StringQualifiers(250)));
	Parameters.ColumnDataType.Insert("BranchOffice",             New TypeDescription("Boolean"));
	Parameters.ColumnDataType.Insert("AccessGroup",                         New TypeDescription("CatalogRef.PartnerAccessGroups"));
	Parameters.ColumnDataType.Insert("LegalEntityIndividual",                             New TypeDescription("EnumRef.LegalEntityIndividual"));
	Parameters.ColumnDataType.Insert("MainCounterparty",                    New TypeDescription("CatalogRef.Partners"));
	Parameters.ColumnDataType.Insert("TIN",                                   Metadata.DefinedTypes.TIN.Type);
	Parameters.ColumnDataType.Insert("CRTR",                                   New TypeDescription("String",, New StringQualifiers(9)));
	Parameters.ColumnDataType.Insert("NCBOCode",                             New TypeDescription("String",, New StringQualifiers(10)));
	Parameters.ColumnDataType.Insert("RegistrationCountry",                     New TypeDescription("CatalogRef.WorldCountries"));
	Parameters.ColumnDataType.Insert("TaxNumber",                        New TypeDescription("String",, New StringQualifiers(50)));
	Parameters.ColumnDataType.Insert("Client",                                New TypeDescription("Boolean"));
	Parameters.ColumnDataType.Insert("Vendor",                             New TypeDescription("Boolean"));
	Parameters.ColumnDataType.Insert("Competitor",                             New TypeDescription("Boolean"));
	Parameters.ColumnDataType.Insert("OtherRelations",                       New TypeDescription("Boolean"));
	Parameters.ColumnDataType.Insert("ServedBySalesRepresentatives", New TypeDescription("Boolean")); 
	Parameters.ColumnDataType.Insert("Carrier",                            New TypeDescription("Boolean"));
	Parameters.ColumnDataType.Insert("Gender",                                   New TypeDescription("EnumRef.GenderPersons"));
	Parameters.ColumnDataType.Insert("BirthDate",                          New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.Date)));
	Parameters.ColumnDataType.Insert("OptionOfSendingElectronicReceipt",       New TypeDescription("EnumRef.OptionsOfSendingElectronicReceiptToCustomer"));
	Parameters.ColumnDataType.Insert("DeliveryZone",                          New TypeDescription("CatalogRef.DeliveryZones"));
	Parameters.ColumnDataType.Insert("PricesKind",                                New TypeDescription("CatalogRef.TypesOfPrices"));
	
	ArrayOfOverviewColumns = New Array;
	ArrayOfOverviewColumns.Add("WorkName");
	ArrayOfOverviewColumns.Add("PublicName");
	ArrayOfOverviewColumns.Add("LegalEntityIndividual");
	ArrayOfOverviewColumns.Add("RegistrationCountry");
	
	Parameters.RequiredColumns2 = ArrayOfOverviewColumns;
	
EndProcedure

// Compares the uploaded data with the data in the IB.
//
// Parameters:
//   DataToImport - ValueTable - table of values with downloadable data:
//     * MappedObject - CatalogRef - A reference to the mapped object. Filled in within the procedure
//
Procedure MatchUploadedDataFromFile(DataToImport) Export

	Query = New Query;
	
	Query.Text =
	"SELECT
	|	DataForComparison.WorkName AS WorkName,
	|	DataForComparison.TaxNumber      AS TaxNumber,
	|	DataForComparison.TIN                 AS TIN,
	|	DataForComparison.CRTR                 AS CRTR,
	|	DataForComparison.Id       AS Id
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForComparison.Id AS Id,
	|	Counterparties.Partner                  AS MappingObject,
	|	1                                    AS PriorityOfMatching
	|INTO MatchingPriorities
	|FROM
	|	DataForComparison AS DataForComparison
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON (Counterparties.TIN = DataForComparison.TIN)
	|			AND DataForComparison.CRTR = Counterparties.CRTR
	|			AND (DataForComparison.TIN <> """")
	|
	|UNION ALL
	|
	|SELECT
	|	DataForComparison.Id,
	|	Counterparties.Partner,
	|	2
	|FROM
	|	DataForComparison AS DataForComparison
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON DataForComparison.TaxNumber = Counterparties.TaxNumber
	|			AND (DataForComparison.TaxNumber <> """")
	|
	|UNION ALL
	|
	|SELECT
	|	DataForComparison.Id,
	|	Counterparties.Partner,
	|	3
	|FROM
	|	DataForComparison AS DataForComparison
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON DataForComparison.WorkName = Counterparties.Description
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MatchingPriorities.Id                   AS Id,
	|	MIN(MatchingPriorities.PriorityOfMatching) AS PriorityOfMatching
	|INTO DefinedPriorities
	|FROM
	|	MatchingPriorities AS MatchingPriorities
	|
	|GROUP BY
	|	MatchingPriorities.Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MatchingPriorities.Id       AS Id,
	|	MatchingPriorities.MappingObject AS MappingObject
	|FROM
	|	MatchingPriorities AS MatchingPriorities
	|		INNER JOIN DefinedPriorities AS DefinedPriorities
	|		ON MatchingPriorities.Id = DefinedPriorities.Id
	|			AND MatchingPriorities.PriorityOfMatching = DefinedPriorities.PriorityOfMatching";
	
	Query.SetParameter("DataForComparison", DataToImport);
	
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		Filter = New Structure("Id", QueryResult.Id);
		Rows = DataToImport.FindRows(Filter);
		For Each String In Rows Do
			String.MappingObject = QueryResult.MappingObject;
		EndDo;
	EndDo;
	
EndProcedure

// Loading data from a file
//
// Parameters:
//   DataToImport - ValueTable - with columns:
//     * MappedObject         - CatalogRef - Reference to the mapped object
//     * RowMappingResult - String       - Download status, possible options: Created, Updated, Skipped   
//     * ErrorDescription               - String       - decoding the data loading error
//     * Id                - Number        - unique line number 
//  ImportParameters                  - Structure    - Boot parameter:
//     * CreateNewItems               - Boolean       - Do I need to create new directory elements?
//     * UpdateExistingItems        - Boolean       - Do I need to update the directory elements?
//  Cancel                              - Boolean       - Canceling the download
//
Procedure LoadFromFile(DataToImport, ImportParameters, Cancel) Export
	
	If DataToImport.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfMatchedPartners     = New Array;
	MatchedPartnersCounterparties = New Map;
	
	For Each TableRow In DataToImport Do
		
		If ValueIsFilled(TableRow.MappingObject) Then
			ArrayOfMatchedPartners.Add(TableRow.MappingObject);
		EndIf;
		
	EndDo;
	
	If ArrayOfMatchedPartners.Count() > 0 Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	MAX(Counterparties.Ref) AS Counterparty,
		|	Counterparties.Partner          AS Partner
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	Counterparties.Partner IN(&ArrayOfPartners)
		|	AND NOT Counterparties.DeletionMark
		|
		|GROUP BY
		|	Counterparties.Partner";
		
		Query.SetParameter("ArrayOfPartners", ArrayOfMatchedPartners);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			MatchedPartnersCounterparties.Insert(Selection.Partner, Selection.Counterparty);
		EndDo;
		
	EndIf;
	
	For Each TableRow In DataToImport Do
		
		MappingObjectIsFull = ValueIsFilled(TableRow.MappingObject);
		
		If (MappingObjectIsFull
			And ImportParameters.UpdateExistingItems = 0)
			Or (Not MappingObjectIsFull
			And ImportParameters.CreateNewItems = 0) Then
				TableRow.RowMappingResult = "Skipped";
				Continue;
		EndIf;
			
		AccessManagement.DisableAccessKeysUpdate(True);
		BeginTransaction();
		
		Try
			
			If MappingObjectIsFull Then
				
				Block        = New DataLock;
				LockItem = Block.Add("Catalog.Partners");
				LockItem.SetValue("Ref", TableRow.MappingObject);
				Block.Lock();
				
				PartnerObject_ = TableRow.MappingObject.GetObject();
				
				If PartnerObject_ = Undefined Then
					ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đã so sánh đối tác với tên gọi %1, nhưng vẫn không tồn tại.';
							|ru = 'Контрагент с наименованием %1 был сопоставлен, но больше не существует.';
							|en = 'The counterparty with the name %1 has been matched but no longer exists.'; fa = 'The counterparty with the name %1 has been matched but no longer exists.';
							|it = 'La controparte con nome %1 è stata associata, ma non esiste più.';
							|pl = 'Kontrahent o nazwie %1 został porównany, ale więcej nie istnieje.';
							|tr = 'Tanımı %1 olan cari hesap eşleştirildi ancak artık mevcut değil.'"), TableRow.WorkName);
						TableRow.ErrorDescription               = ErrorDescription;
					TableRow.RowMappingResult = "Skipped";
					Continue;
				EndIf;
				
				PartnerSCounterparty = MatchedPartnersCounterparties.Get(TableRow.MappingObject);
				
				If PartnerSCounterparty = Undefined Then
					
					CounterpartyObject = Catalogs.Counterparties.CreateItem();
					
				Else
					
					CounterpartyObject = PartnerSCounterparty.GetObject();
					
				EndIf;
				
				TableRow.RowMappingResult = "Updated";
				
			Else
				
				PartnerObject_     = CreateItem();
				CounterpartyObject  = Catalogs.Counterparties.CreateItem();
				TableRow.RowMappingResult = "Created";
				
			EndIf;
			
			If ValueIsFilled(TableRow.WorkName) Then
				PartnerObject_.Description = TableRow.WorkName;
			EndIf;
			
			If ValueIsFilled(TableRow.PublicName) Then
				PartnerObject_.DescriptionFull = TableRow.PublicName;
			EndIf;
			
			If ValueIsFilled(TableRow.LegalEntityIndividual) Then
				
				If TableRow.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity
					Or  TableRow.LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident Then
					
					PartnerObject_.LegalEntityIndividual  = Enums.IndividualCompany.Company;
					
				Else
					
					PartnerObject_.LegalEntityIndividual  = Enums.IndividualCompany.Person_;
					
				EndIf;
				
			EndIf;
			
			If ValueIsFilled(TableRow.MainCounterparty) Then
				PartnerObject_.Parent = TableRow.MainCounterparty;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "AccessGroup")
				 And ValueIsFilled(TableRow.AccessGroup) Then
				PartnerObject_.AccessGroup = TableRow.AccessGroup;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "PricesKind")
				And ValueIsFilled(TableRow.PricesKind) Then
				 PartnerObject_.PricesKind = TableRow.PricesKind;
			EndIf;
			
			If ValueIsFilled(TableRow.BirthDate) Then
				PartnerObject_.BirthDate = TableRow.BirthDate;
			EndIf;
			
			If ValueIsFilled(TableRow.Gender) Then
				 PartnerObject_.Gender = TableRow.Gender;
			EndIf;
			
			If ValueIsFilled(TableRow.BirthDate) Then
				PartnerObject_.BirthDate = TableRow.BirthDate;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "OptionOfSendingElectronicReceipt")
					And ValueIsFilled(TableRow.OptionOfSendingElectronicReceipt) Then
				 PartnerObject_.OptionOfSendingElectronicReceipt = TableRow.OptionOfSendingElectronicReceipt;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "DeliveryZone")
				And ValueIsFilled(TableRow.DeliveryZone) Then
				PartnerObject_.DeliveryZone = TableRow.DeliveryZone;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "Client") Then
				PartnerObject_.Client = TableRow.Client;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "Competitor") Then
				PartnerObject_.Competitor = TableRow.Competitor;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "Vendor") Then
				PartnerObject_.Vendor = TableRow.Vendor;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "OtherRelations") Then
				PartnerObject_.OtherRelations = TableRow.OtherRelations;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "ServedBySalesRepresentatives") Then
				PartnerObject_.ServedBySalesRepresentatives = TableRow.ServedBySalesRepresentatives;
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "Carrier") Then
				PartnerObject_.Carrier = TableRow.Carrier;
			EndIf;
			
			If Not PartnerObject_.CheckFilling() Then
				
				TableRow.RowMappingResult = "Skipped";
				UserMessages = GetUserMessages(True);
				If UserMessages.Count() > 0 Then
					MessagesText = "";
					For Each UserMessage In UserMessages Do
						MessagesText  = MessagesText + UserMessage.Text + Chars.LF;
					EndDo;
					TableRow.ErrorDescription = MessagesText;
				EndIf;
				RollbackTransaction();
				Continue;
				
			Else
				
				PartnerObject_.Write();
				TableRow.MappingObject = PartnerObject_.Ref;
				
				CounterpartyObject.Partner = PartnerObject_.Ref;
				
				CounterpartyObject.Description              = PartnerObject_.Description;
				CounterpartyObject.DescriptionFull        = PartnerObject_.DescriptionFull;
				CounterpartyObject.Partner                   = PartnerObject_.Ref;
				
				If ValueIsFilled(TableRow.LegalEntityIndividual) Then
				
					CounterpartyObject.LegalEntityIndividual                 = TableRow.LegalEntityIndividual;
					
				EndIf; 
				CounterpartyObject.BranchOffice = TableRow.BranchOffice;
				
				If ValueIsFilled(TableRow.RegistrationCountry) Then
				
					CounterpartyObject.RegistrationCountry = TableRow.RegistrationCountry;
					
				EndIf;
				
				If ValueIsFilled(TableRow.DescriptionInternational) Then
					
					CounterpartyObject.DescriptionInternational = TableRow.DescriptionInternational;
					
				EndIf;
				
				If ValueIsFilled(TableRow.TaxNumber) Then
					
					CounterpartyObject.TaxNumber = TableRow.TaxNumber;
					
				EndIf;
				
				If ValueIsFilled(TableRow.RegistrationNumber) Then
					
					CounterpartyObject.RegistrationNumber = TableRow.RegistrationNumber;
					
				EndIf;
				
				If ValueIsFilled(TableRow.TIN) Then
					
					CounterpartyObject.TIN = TableRow.TIN;
					
				EndIf;
				
				If ValueIsFilled(TableRow.CRTR) Then
					
					CounterpartyObject.CRTR = TableRow.CRTR;
					
				EndIf;
				
				If ValueIsFilled(TableRow.NCBOCode) Then
					
					CounterpartyObject.NCBOCode = TableRow.NCBOCode;
					
				EndIf;
				
				CounterpartyObject.Write();
				
				AccessManagement.DisableAccessKeysUpdate(False);
				CommitTransaction();
				
			EndIf;
			
		Except
			
			RollbackTransaction();
			AccessManagement.DisableAccessKeysUpdate(False, False);
			Cause = BriefErrorDescription(ErrorInfo());
			TableRow.RowMappingResult = "Skipped";
			TableRow.ErrorDescription = NStr("vi = 'Không thể ghi lại dữ liệu do nguyên nhân:';
											|ru = 'Невозможна запись данных по причине:';
											|en = 'Cannot save the data due to:'; fa = 'Cannot save the data due to:';
											|it = 'Impossibile salvare i dati a causa di:';
											|pl = 'Zapisywanie danych jest niemożliwe z powodu:';
											|tr = 'Şu nedenlerle veri kaydedilmiyor:'") + Chars.LF + Cause;
			
		EndTry;

	EndDo;
	
EndProcedure

//End StandardSubsystems.ImportDataFromFile

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Result = PartnersAndCounterpartiesServerCall.PartnersSelectionData(Parameters);
	
	If Result <> Undefined Then
		
		StandardProcessing = False;
		ChoiceData = Result;
		
	EndIf;
	
EndProcedure

#EndIf

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	UseFullTextSearch = GeneralPurposeTMServerCall.FullTextSearchIsUsed("UseFullTextSearch");
	
	If FormType = "ObjectForm" Then
		
		If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
			
			SelectedForm = "WizardOfNew";
			StandardProcessing = False;

		ElsIf GetFunctionalOption("UsePartnersAsCounterparties") Then
			
			SelectedForm = "CounterpartyAttributesItemForm";
			StandardProcessing = False;
			
		EndIf;
		
	ElsIf FormType = "ChoiceForm" And Not UseFullTextSearch Then 
		
		SelectedForm = "SelectionFormWithoutFullTextSearch";
		StandardProcessing = False;
		
	ElsIf FormType = "ListForm" And Not UseFullTextSearch Then 
		
		SelectedForm = "ListFormWithoutFullTextSearch";
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Assignments

// Returns a template for generating an assignment
//
// Parameters:
// 		Object - CatalogObject.Partners, FormDataStructure - the object to get the destination template for.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function ProcessorAssignmentTemplate(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	DestinationPattern.Partner = Object.Ref;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// Fills in predefined elements of the Partners directory.
//
Procedure FillInPredefinedPartners() Export
	
	CatalogObject = Catalogs.Partners.OurEnterprise.GetObject();
	CatalogObject.RegistrationDate = Date(1980, 1, 1);
	CatalogObject.DescriptionFull = NStr("vi = 'Doanh nghiệp chúng ta';
										|ru = 'Наше предприятие';
										|en = 'Our enterprise'; fa = 'سازمان ما';
										|it = 'La nostra impresa';
										|pl = 'Nasze przedsiębiorstwo';
										|tr = 'İşletmemiz'");
	CatalogObject.LegalEntityIndividual = Enums.IndividualCompany.Company;
	
	CatalogObject.Write();
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		ArrayOfPartners = PartnersAndCounterparties.GetAllPartnersOfPartner(CatalogObject.Ref);
		If ArrayOfPartners.Count() = 0 Then
			Counterparty = Catalogs.Counterparties.CreateItem();
			Counterparty.Description = CatalogObject.Description;
			Counterparty.DescriptionFull = CatalogObject.DescriptionFull;
			Counterparty.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity;
			Counterparty.Partner = CatalogObject.Ref;
			Counterparty.Write();
		EndIf;
	EndIf;
	
	CatalogObject = Catalogs.Partners.RetailCustomer.GetObject();
	CatalogObject.Client = True;
	CatalogObject.RegistrationDate = Date(1980, 1, 1);
	CatalogObject.DescriptionFull = NStr("vi = 'Khách lẻ';
										|ru = 'Розничный покупатель';
										|en = 'Retail customer'; fa = 'Retail customer';
										|it = 'Compratore al dettaglio';
										|pl = 'Klient detaliczny';
										|tr = 'Perakende müşteri'");
	CatalogObject.LegalEntityIndividual = Enums.IndividualCompany.Person_;
	CatalogObject.Write();
	// The counterparty "Retail buyer" is filled in in the corresponding procedure in the module of the manager of the directory "Counterparties".
	
	CatalogObject = Catalogs.Partners.UnknownPartner.GetObject();
	CatalogObject.Client = True;
	CatalogObject.Vendor = True;
	CatalogObject.OtherRelations = True;
	CatalogObject.RegistrationDate = Date(1980, 1, 1);
	CatalogObject.DescriptionFull = NStr("vi = 'Bạn hàng không xác định';
										|ru = 'Неизвестный партнер';
										|en = 'Unknown partner'; fa = 'Unknown partner';
										|it = 'Partner sconosciuto';
										|pl = 'Nieznany partner';
										|tr = 'Bilinmeyen iş ortağı'");
	CatalogObject.LegalEntityIndividual = Enums.IndividualCompany.Company;
	CatalogObject.Write();
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.Partners.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("95824992-4f28-4d86-ab9e-99e9e5c15da4");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.Partners.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Bạn hàng"":';
								|ru = 'Обновление справочника ""Партнеры"":';
								|en = 'Update the ""Partners"" catalog:'; fa = 'Update the ""Partners"" catalog:';
								|it = 'Update the ""Partners"" catalog:';
								|pl = 'Update the ""Partners"" catalog:';
								|tr = '""İş ortakları"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền dữ liệu xml của thông tin liên hệ';
								|ru = '- Заполнение xml данных контактной информации';
								|en = '- Fill XML contact information data'; fa = '- Fill XML contact information data';
								|it = '- Fill XML contact information data';
								|pl = '- Fill XML contact information data';
								|tr = '- İletişim bilgilerine ait xml formatında verilerin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.Partners.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.Partners.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.Partners.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryParts = New Array;
	QueryParts.Add(
	"SELECT
	|	PartnersContactInformation.Ref AS Ref
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	(CAST(PartnersContactInformation.FieldValues AS STRING(1))) = ""{""");
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If AdditionalLanguagesAreUsed Then
		
		QueryParts.Add(
			"SELECT
			|	Partners.Ref AS Ref
			|FROM
			|	Catalog.Partners AS Partners
			|WHERE
			|	NOT Partners.Description = """"
			|	AND Partners.DescriptionLanguage1 = """"
			|	
			|UNION 
			|
			|SELECT
			|	Partners.Ref AS Ref
			|FROM
			|	Catalog.Partners AS Partners
			|WHERE
			|	NOT Partners.Description = """"
			|	AND Partners.DescriptionLanguage2 = """"
			|	
			|UNION 
			|
			|SELECT
			|	Partners.Ref AS Ref
			|FROM
			|	Catalog.Partners AS Partners
			|WHERE
			|	NOT CAST(Partners.Comment AS STRING(150)) = """"
			|	AND CAST(Partners.CommentLanguage1 AS STRING(150)) = """"
			|	
			|UNION 
			|
			|SELECT
			|	Partners.Ref AS Ref
			|FROM
			|	Catalog.Partners AS Partners
			|WHERE
			|	NOT CAST(Partners.Comment AS STRING(150)) = """"
			|	AND CAST(Partners.CommentLanguage2 AS STRING(150)) = """"
			|");
			
	EndIf;
	
	Query = New Query;
	Query.Text = StrConcat(QueryParts, 
	"
	|
	|UNION ALL
	|
	|");
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Bạn hàng"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Партнеры"" по обработчику:';
								|en = 'Cannot process the ""Partners"" catalog by the handler:'; fa = 'Cannot process the ""Partners"" catalog by the handler:';
								|it = 'Cannot process the ""Partners"" catalog by the handler:';
								|pl = 'Cannot process the ""Partners"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""İş ortakları"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền dữ liệu xml của thông tin liên hệ';
								|ru = '- Заполнение xml данных контактной информации';
								|en = '- Fill XML contact information data'; fa = '- Fill XML contact information data';
								|it = '- Fill XML contact information data';
								|pl = '- Fill XML contact information data';
								|tr = '- İletişim bilgilerine ait xml formatında verilerin doldurulması'"));
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	Partners.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON TT.Ref = Partners.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				For Each CIRow In CatalogObject.ContactInformation Do
					
					If ContactsManagerClientServer.IsJSONContactInformation(CIRow.FieldValues) Then
						
						ContactsManagerLocalization.OnConvertContactInformationFromJSONToXML(CIRow.FieldValues, CIRow.FieldValues);
						
					EndIf;
					
				EndDo;
				
				If AdditionalLanguagesAreUsed Then
					
					If ValueIsFilled(CatalogObject.Description) Then
						
						If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
							
							CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
							
						EndIf;
						
						If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
							
							CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
							
						EndIf;
						
					EndIf;
					
					If ValueIsFilled(CatalogObject.Comment) Then
						
						If Not ValueIsFilled(CatalogObject.CommentLanguage1) Then
							
							CatalogObject.CommentLanguage1 = CatalogObject.Comment;
							
						EndIf;
						
						If Not ValueIsFilled(CatalogObject.CommentLanguage2) Then
							
							CatalogObject.CommentLanguage2 = CatalogObject.Comment;
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Ref";

	ArrayOfRecipientDetails = PrintObjectDataStructure.ArrayOfRecipientDetails; // Array
	ArrayOfRecipientDetails.Add("Ref");
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.PartnerProfile.AddPartnerDossierTeam(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
	EndIf;
	
	ReportCommand = Reports.FulfillmentOfRegularConditionsOfTermsOfSales.AddFulfillmentOfTermsOfAgreementsWithClientsForPartnerTeam(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
	EndIf;
	
	ReportCommand = Reports.RevenueAndCOGS.AddSalesTeam(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch,CounterpartyAttributesItemForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch,CounterpartyAttributesItemForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch,CounterpartyAttributesItemForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch,CounterpartyAttributesItemForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch,CounterpartyAttributesItemForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch,CounterpartyAttributesItemForm";
	EndIf;
	
	ReportCommand = Reports.PurchaseConditions.AddVendorReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch,CounterpartyAttributesItemForm";
	EndIf;
	
	ReportCommand = Reports.SalesTermsAndConditions.AddPartnerReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
	EndIf;
	
	ReportCommand = Reports.SalesTermsAndConditions2_5.AddPartnerReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
	EndIf;
	
	ReportCommand = Reports.ContactInformation.AddTeamContactInformationForPartners(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
	EndIf;
	
	ReportCommand = Reports.ContactInformation.AddTeamContactInformationOfContactPersons(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
	EndIf;
	
	ReportCommand = TMReportOptionsOverridable.AddContactInteractionCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
	EndIf;
	
	ReportCommand = TMReportOptionsOverridable.AddPartnerSegmentsCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
	EndIf;
	
	ReportCommand = Reports.ActiveCustomerRebates.AddReportCommand(
		ReportsCommands,
		Parameters,
		"CurrentRebatesForClientContext");
	If ReportCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"Client",
			True,
			DataCompositionComparisonType.Equal);
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch";
		
	EndIf;
	
	ReportCommand = Reports.ActiveVendorRebates.AddReportCommand(
		ReportsCommands, Parameters, "CurrentRebatesOfSuppliersContext");
	If ReportCommand <> Undefined Then
		
		Presentation = NStr("vi = 'Thưởng lũy kế của nhà cung cấp đang có hiệu lực';
							|ru = 'Действующие ретро-бонусы поставщика';
							|en = 'Active vendor rebates'; fa = 'تخفیف‌های حجمی فعال فروشنده';
							|it = 'Действующие ретро-бонусы поставщика';
							|pl = 'Active vendor rebates';
							|tr = 'Sağlayıcının geçerli retro bonusları'");
		ReportCommand.Presentation = Presentation;
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"Vendor",
			True,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	PartnersAndCounterpartiesLocalization.AddReportCommands_Partners(ReportsCommands, Parameters);
EndProcedure

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
