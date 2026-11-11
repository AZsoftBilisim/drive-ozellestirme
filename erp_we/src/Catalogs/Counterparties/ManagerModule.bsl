#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.PartnerHierarchy AS T2 
	|	ON T2.Parent = T.Partner
	|;
	|AllowRead
	|WHERE
	|	ValueAllowed(T2.Partner)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy 
	|	ON PartnerHierarchy.Parent = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = PartnerHierarchy.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners 
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
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

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

Function AbbreviatedLegalEntityNameAsOfDate(Counterparty, DateOfLastEdit) Export
	
	If Not ValueIsFilled(Counterparty)
		Or TypeOf(Counterparty) <> Type("CatalogRef.Counterparties") Then
		Return "";
	EndIf;
	
	If Not ValueIsFilled(DateOfLastEdit) Then
		Return Common.ObjectAttributeValue(Counterparty, "DescriptionFull");
	EndIf;
	
	Query = New Query;
	Query.Parameters.Insert("Counterparty", Counterparty);
	Query.Parameters.Insert("DateOfLastEdit", DateOfLastEdit);
	Query.Text ="
	|SELECT ALLOWED TOP 1
	|	HistoryOfCounterpartyNames.NameAbbreviated AS NameAbbreviated
	|INTO HistoricalSignificanceOfName
	|FROM
	|	Catalog.Counterparties.NameHistory AS HistoryOfCounterpartyNames
	|WHERE
	|	HistoryOfCounterpartyNames.Ref = &Counterparty
	|	AND HistoryOfCounterpartyNames.Period <= &DateOfLastEdit
	|
	|ORDER BY
	|	HistoryOfCounterpartyNames.Period DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ISNULL(HistoricalSignificanceOfName.NameAbbreviated, Counterparties.DescriptionFull) AS DescriptionFull
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|		LEFT JOIN HistoricalSignificanceOfName AS HistoricalSignificanceOfName
	|		ON (TRUE)
	|WHERE
	|	Counterparties.Ref = &Counterparty";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.DescriptionFull;
	Else
		Return "";
	EndIf;
	
EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("CompanyIndividual");
	NotAttributesToEdit.Add("BranchOffice");
	NotAttributesToEdit.Add("MainCounterparty");
	NotAttributesToEdit.Add("DescriptionFull");
	NotAttributesToEdit.Add("NameHistory.*");
	PartnersAndCounterpartiesLocalization.AddDetailsThatCannotBeEditedInGroupProcessingCounterparty(NotAttributesToEdit);
	Return NotAttributesToEdit;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	Catalogs.TermsOfSale.AddGenerateCommand(GenerationCommands);
	
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
	
	#Region RetailCustomer
	Item = Items.Add();
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
	Item.CompanyIndividual = Enums.CompanyIndividual.Individual;
	Item.MainCounterparty = Catalogs.Counterparties.RetailCustomer;
	Item.Partner = Catalogs.Partners.RetailCustomer;
	Item.LegalEntityIndividual = Enums.LegalEntityIndividual.Person;
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.Counterparties - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = PartnersAndCounterpartiesServerCall.CounterpartiesSelectionData(Parameters);
	
EndProcedure

#EndIf

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ChoiceForm" Then
		
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			
			UseFullTextSearch = GeneralPurposeTMServerCall.FullTextSearchIsUsed("UseFullTextSearch");
			
			If UseFullTextSearch Then
				SelectedForm       = "ChoiceFormOnlyPartnersAreUsed";
			Else
				SelectedForm       = "ChoiceFormOnlyPartnersAreUsedWithoutFullTextSearch";
			EndIf;
			
			StandardProcessing = False;
			
		EndIf;
		
	EndIf;
	
	If FormType = "ObjectForm" Then
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			StandardProcessing = False;
			If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
				PartnersAndCounterpartiesServerCall.CounterpartyDataForOpeningPartnerForm(Parameters);
				SelectedForm = "Catalog.Partners.Form.CounterpartyAttributesItemForm";
			Else
				SelectedForm = "Catalog.Partners.Form.WizardOfNew";
			EndIf;
		EndIf;
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

#Region InitialInfobaseFilling

// Fills in predefined elements of the "Contractors"directory.
//
Procedure FillInPredefinedCounterparties() Export
	
	CatalogObject = Catalogs.Counterparties.RetailCustomer.GetObject();
	CatalogObject.DescriptionFull = NStr("vi = 'Khách lẻ';
										|ru = 'Розничный покупатель';
										|en = 'Retail customer'; fa = 'Retail customer';
										|it = 'Compratore al dettaglio';
										|pl = 'Klient detaliczny';
										|tr = 'Perakende müşteri'", Common.DefaultLanguageCode());
	CatalogObject.LegalEntityIndividual = Enums.LegalEntityIndividual.Person;
	CatalogObject.Partner = Catalogs.Partners.RetailCustomer;
	CatalogObject.Write();
	
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
	
	ReportCommand = ARAPAccountingServer.StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ParametricListForm";
	EndIf;
	
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ParametricListForm";
	EndIf;
	
	ReportCommand = Reports.ActiveCustomerRebates.AddReportCommand(
		ReportsCommands, Parameters, "CurrentRebatesForCounterpartyContext");
	If ReportCommand <> Undefined Then
		
		Presentation = NStr("vi = 'Thưởng lũy kế đang có hiệu lực theo khách hàng';
							|ru = 'Действующие ретро-бонусы по клиенту';
							|en = 'Active rebates by customer'; fa = 'تخفیف‌های حجمی فعال بر اساس مشتری';
							|it = 'Действующие ретро-бонусы по клиенту';
							|pl = 'Active rebates by customer';
							|tr = 'Müşteriye göre geçerli retro-bonuslar'");
		ReportCommand.Presentation = Presentation;
		
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
		
	EndIf;
	
	PartnersAndCounterpartiesLocalization.AddReportCommands_Counterparties(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export



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

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.Counterparties.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("6283c4c0-b59c-4f96-8d9e-35b0b1f46557");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.Counterparties.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Đối tác"":';
								|ru = 'Обновление справочника ""Контрагенты"":';
								|en = 'Update the ""Counterparties"" catalog:'; fa = 'Update the ""Counterparties"" catalog:';
								|it = 'Update the ""Counterparties"" catalog:';
								|pl = 'Update the ""Counterparties"" catalog:';
								|tr = '""Cari hesaplar"" kataloğunun güncellenmesi'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin danh mục đa ngôn ngữ';
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
	ItemsToRead.Add(Metadata.Catalogs.Counterparties.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.Counterparties.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.Counterparties.FullName());
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
	|	CounterpartiesContactInformation.Ref AS Ref
	|FROM
	|	Catalog.Counterparties.ContactInformation AS CounterpartiesContactInformation
	|WHERE
	|	(CAST(CounterpartiesContactInformation.FieldValues AS STRING(1))) = ""{""");

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
		|	Counterparties.Ref AS Ref
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	NOT Counterparties.Description = """"
		|	AND Counterparties.DescriptionLanguage1 = """"
		|	
		|UNION 
		|
		|SELECT
		|	Counterparties.Ref AS Ref
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	NOT Counterparties.Description = """"
		|	AND Counterparties.DescriptionLanguage2 = """"");
	
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
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Đối tác"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Контрагенты"" по обработчику:';
								|en = 'Cannot process the ""Counterparties"" catalog by the handler:'; fa = 'Cannot process the ""Counterparties"" catalog by the handler:';
								|it = 'Cannot process the ""Counterparties"" catalog by the handler:';
								|pl = 'Cannot process the ""Counterparties"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Cari hesaplar"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin danh mục đa ngôn ngữ';
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
	|	Counterparties.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.Counterparties AS Counterparties
	|		ON TT.Ref = Counterparties.Ref";
	
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
					
					If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
						
						CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
						
					EndIf;
					
					If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
						
						CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
						
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

#EndRegion

#EndIf
