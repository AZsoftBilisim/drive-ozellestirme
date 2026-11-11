///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Function ValidateAddress(Address, AddressCheckParameters = Undefined) Export
	
	CheckResult = CheckResult(); 
	
	If TypeOf(Address) <> Type("String") Then
		CheckResult.Result = "ContainsErrors";
		CheckResult.ErrorList.Add("AddressFormat", NStr("vi = 'Sai định dạng địa chỉ';
														|ru = 'Некорректный формат адреса';
														|en = 'Invalid address format'; fa = 'Invalid address format';
														|it = 'Il formato dell''indirizzo è scorretto';
														|pl = 'Nieprawidłowy format adresu';
														|tr = 'Yanlış adres biçimi'"));
		Return CheckResult;
	EndIf;
	
	If Metadata.DataProcessors.Find("AdvancedContactInformationInput") <> Undefined Then
		ModuleAdvancedContactInformationInput = Common.CommonModule("DataProcessors.AdvancedContactInformationInput");
		ModuleAdvancedContactInformationInput.ValidateAddress(Address, CheckResult, AddressCheckParameters);
	EndIf;
	
	Return CheckResult;
	
EndFunction

Function ConvertContactInformationToJSONFormat(ReferenceOrObject, ObjectType) Export
	
	ObjectModified = False;
	If Common.IsReference(ObjectType) Then
		If Not ContainsBlankJSONFields(ReferenceOrObject) Then
			Return False;
		EndIf;
		ObjectModified = FillContactInformationJSONFieldsForRef(ReferenceOrObject);
	Else
		ObjectModified = FillContactInformationJSONFieldsForObject(ReferenceOrObject);
	EndIf;
	
	Return ObjectModified;
	
EndFunction


// Searches for contacts with email addresses.
// 
// Parameters:
//  SearchString - String - search text
//  ContactsDetails - Array of See NewContactDescription
// Returns:
//   ValueTable:
//   * Contact               - DefinedType.InteractionContact - a found contact.
//   * Description          - String - contact name.
//   * OwnerDescription1 - String - a contact owner name.
//   * Presentation         - String - Email address.
//   
//
Function FindContactsWithEmailAddresses(SearchString, ContactsDetails) Export
	
	QueryText = 
	"SELECT ALLOWED DISTINCT TOP 20
	|	CatalogContact.Ref AS Contact,
	|	PRESENTATION(CatalogContact.Ref) AS Description,
	|	"""" AS OwnerDescription1,
	|	ContactInformationTable.EMAddress AS Presentation
	|FROM
	|	Catalog.Users AS CatalogContact
	|		INNER JOIN Catalog.Users.ContactInformation AS ContactInformationTable
	|		ON (ContactInformationTable.Ref = CatalogContact.Ref)
	|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.Email))
	|			AND (ContactInformationTable.EMAddress <> """")
	|WHERE
	|	NOT CatalogContact.DeletionMark
	|	AND (CatalogContact.Description LIKE &EnteredString ESCAPE ""~""
	|			OR ContactInformationTable.EMAddress LIKE &EnteredString ESCAPE ""~""
	|			OR ContactInformationTable.ServerDomainName LIKE &EnteredString ESCAPE ""~""
	|			OR ContactInformationTable.Presentation LIKE &EnteredString ESCAPE ""~"")";
	
	For Each ContactDescription In ContactsDetails Do
		
		If ContactDescription.Name = "Users" Then
			Continue; // Skip.
		EndIf;
			
		InputFieldsConditionByString = "";
		ObjectMetadata = Metadata.FindByType(ContactDescription.Type);
		FieldList = ObjectMetadata.InputByString; // FieldList
		For Each Field In FieldList Do
			FieldOfStringType = False;
			If CommonClientServer.HasAttributeOrObjectProperty(ObjectMetadata.StandardAttributes, Field.Name) Then 
				If ObjectMetadata.StandardAttributes[Field.Name].Type.Types()[0] = Type("String") Then
					FieldOfStringType = True;
				EndIf;
			ElsIf CommonClientServer.HasAttributeOrObjectProperty(ObjectMetadata.Attributes, Field.Name) Then 
				If ObjectMetadata.Attributes[Field.Name].Type.Types()[0] = Type("String") Then
					FieldOfStringType = True;
				EndIf;
			EndIf;
			If FieldOfStringType Then
				InputFieldsConditionByString = InputFieldsConditionByString + " " 
					+ StringFunctionsClientServer.SubstituteParametersToString(
						"OR CatalogContact.%1 LIKE &EnteredString ESCAPE ""~""",
						Field.Name);
			EndIf;
		EndDo;
		
		QueryText = QueryText + "
		|UNION ALL
		|";
		
		QueryText = QueryText + "
		|SELECT DISTINCT TOP 20
		|	CatalogContact.Ref AS Contact,
		|	&TheNameField AS Description,
		|	&TheNameFieldOfTheOwner AS OwnerDescription1,
		|	ContactInformationTable.EMAddress AS Presentation
		|FROM
		|	&ReferenceTable AS CatalogContact
		|		INNER JOIN TheNameOfTheTableContactInformation AS ContactInformationTable
		|		ON (ContactInformationTable.Ref = CatalogContact.Ref)
		|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.Email) 
		|			AND (ContactInformationTable.EMAddress <> """"))
		|WHERE
		|	NOT CatalogContact.DeletionMark 
		|	AND (ContactInformationTable.EMAddress LIKE &EnteredString ESCAPE ""~""
		|		OR ContactInformationTable.ServerDomainName LIKE &EnteredString ESCAPE ""~""
		|		OR ContactInformationTable.Presentation LIKE &EnteredString ESCAPE ""~""
		|		AND &InputFieldsConditionByString) 
		|";
		
		QueryText = StrReplace(QueryText, "&TheNameFieldOfTheOwner" , ?(ContactDescription.HasOwner, 
			"PRESENTATION(CatalogContact.Owner)", """"""));
		QueryText = StrReplace(QueryText, "&TheNameField" , "CatalogContact." 
			+ ContactDescription.ContactPresentationAttributeName);
		QueryText = StrReplace(QueryText, "&ReferenceTable" ,"Catalog." + ContactDescription.Name);
		QueryText = StrReplace(QueryText, "TheNameOfTheTableContactInformation" ,"Catalog." 
			+ ContactDescription.Name + ".ContactInformation");
		QueryText = StrReplace(QueryText, "AND &InputFieldsConditionByString" , InputFieldsConditionByString);
		
	EndDo;
	
	Query = New Query(QueryText);
	Query.SetParameter("EnteredString", "%" + Common.GenerateSearchQueryString(SearchString) + "%");
	Return Query.Execute().Unload(); 
	
EndFunction


// New contact details with email addresses for search.
//
// Returns:
//   Structure:
//     * Type                               - Type    - a contact reference type.
//     * Name                               - String - a contact type name as it is defined in metadata.
//     * HasOwner                      - Boolean - indicates that the contact has an owner.
//     * ContactPresentationAttributeName - String - a contact attribute name, from which a contact presentation
//                                                    will be received. If it is not specified, the standard
//                                                    Description attribute is used.
//
Function NewContactDescription() Export
	
	Result = New Structure;
	Result.Insert("Type",                               "");
	Result.Insert("Name",                               "");
	Result.Insert("HasOwner",                      False);
	Result.Insert("ContactPresentationAttributeName", "Description");
	Return Result;
	
EndFunction

Function CountriesCodes() Export
	
	Return Catalogs.WorldCountries.CountriesCodes();
	
EndFunction

Function WorldCountriesCatalogEmptyRef() Export
	
	Return Catalogs.WorldCountries.EmptyRef();

EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See ObjectsVersioningOverridable.OnPrepareObjectData.
Procedure OnPrepareObjectData(Object, AdditionalAttributes) Export 
	
	If Object.Metadata().TabularSections.Find("ContactInformation") <> Undefined Then
		ObjectContactInformation = ContactsManager.ObjectContactInformation(Object.Ref,, CurrentSessionDate(), False);
		ContactInfoKindsDescription = Common.ObjectsAttributeValue(ObjectContactInformation.UnloadColumn("Kind"), "Description");
		For Each Contact In ObjectContactInformation Do
			If ValueIsFilled(Contact.Kind) Then
				Attribute = AdditionalAttributes.Add();
				Attribute.Description = ContactInfoKindsDescription.Get(Contact.Kind);
				Attribute.Value = Contact.Presentation;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Importing to the countries classifier is denied.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.WorldCountries.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See ObjectAttributesLockOverridable.OnDefineObjectsWithLockedAttributes.
Procedure OnDefineObjectsWithLockedAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.ContactInformationKinds.FullName(), "");
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.ContactInformationKinds.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version    = "2.2.3.34";
	Handler.Procedure = "ContactsManagerInternal.UpdateExistingWorldCountries";
	Handler.ExecutionMode = "Exclusively";
	Handler.SharedData      = False;
	
	Handler = Handlers.Add();
	Handler.Version    = "2.3.1.8";
	Handler.Procedure = "ContactsManagerInternal.UpdatePhoneExtensionSettings";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData      = False;
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version    = "2.3.1.15";
	Handler.Procedure = "ContactsManagerInternal.SetUsageFlagValue";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData      = False;
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version          = "3.1.3.148";
	Handler.Id   = New UUID("dfc6a0fa-7c7b-4096-9d04-2c67d5eb17a4");
	Handler.Procedure       = "Catalogs.WorldCountries.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.WorldCountries.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead    = "Catalog.WorldCountries";
	Handler.ObjectsToChange  = "Catalog.WorldCountries";
	Handler.ObjectsToLock = "Catalog.WorldCountries";
	Handler.CheckProcedure  = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật thông tin về các quốc gia trên thế giới theo hệ thống phân loại các quốc gia trên thế giới.
		|Trước khi hoàn tất xử lý, trong một số trường hợp, tên các quốc gia trong chứng từ sẽ hiển thị không chính xác.';
		|ru = 'Обновление сведений о странах мирах в соответствии с общероссийским классификатором стран мира.
		|До завершения обработки наименование стран в документах в ряде случаев будет отображаться некорректно.';
		|en = 'Updates Countries details against the Country classifier.
		|Until it is complete, some country names might not be shown correctly.'; fa = 'Updates Countries details against the Country classifier.
		|Until it is complete, some country names might not be shown correctly.';
		|it = 'Aggiornamento dati sui paesi del mondo in conformità al classificatore unico della Russia dei paesi del mondo. 
		|Fino al termine di elaborazione in alcuni casi i nomi dei paesi nei documenti potrebbero essere visualizzati nel modo scorretto.';
		|pl = 'Aktualizacja informacji o krajach zgodnie z ogólnorosyjskim klasyfikatorem krajów.
		|Do zakończenia przetwarzania nazwy krajów w dokumentach w niektórych przypadkach mogą nie być wyświetlane poprawnie.';
		|tr = 'Dünya ülkeleri hakkındaki bilgileri, Tekdüzen Rus dünya ülkeleri sınıflandırıcısına göre güncelleyin.
		| İşleme tamamlanmadan önce, bazı durumlarda belgelerdeki ülke adı düzgün görüntülenmez.'");

	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		NewRow = Handler.ExecutionPriorities.Add();
		NewRow.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
		NewRow.Order = "Before";
	EndIf;

	Handler = Handlers.Add();
	Handler.Version          = "3.1.10.117";
	Handler.Id   = New UUID("22f43dca-ac4f-3289-81a9-e110cd56f8b2");
	Handler.Procedure       = "Catalogs.ContactInformationKinds.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.ContactInformationKinds.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead    = "Catalog.ContactInformationKinds";
	Handler.ObjectsToChange  = "Catalog.ContactInformationKinds";
	Handler.ObjectsToLock = "Catalog.ContactInformationKinds";
	Handler.CheckProcedure  = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đang cập nhật các dạng thông tin liên hệ.
		|Trước khi quá trình xử lý hoàn tất, các dạng thông tin liên hệ trong chứng từ trong một số trường hợp sẽ được hiển thị không chính xác.';
		|ru = 'Обновление видов контактной информации.
		|До завершения обработки виды контактной информации в документах в ряде случаев будут отображаться некорректно.';
		|en = 'Updates contact information kinds.
		|While the update is in progress, names of contact information kinds in documents might be displayed incorrectly.'; fa = 'Updates contact information kinds.
		|While the update is in progress, names of contact information kinds in documents might be displayed incorrectly.';
		|it = 'Aggiornamento dei tipi di informazioni di contatto. 
		|Fino al termine di elaborazione i tipi di informazioni di contatto potrebbero non essere visualizzati correttamente in alcuni casi.';
		|pl = 'Aktualizacja rodzajów informacji kontaktowej.
		|Do zakończenia przetwarzania rodzaje informacji kontaktowej w dokumentach w niektórych przypadkach będą odzwierciedlane niepoprawnie.';
		|tr = 'İletişim bilgileri türlerinin güncellenmesi.
		|İşleme tamamlanmadan belgelerdeki iletişim bilgi türleri belirli durumlarda yanlış görüntülenecektir.'");
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		NewRow = Handler.ExecutionPriorities.Add();
		NewRow.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
		NewRow.Order = "Before";
	EndIf;
	
EndProcedure

// See DuplicateObjectsDetectionOverridable.OnDefineObjectsWithSearchForDuplicates.
Procedure OnDefineObjectsWithSearchForDuplicates(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.ContactInformationKinds.FullName(), "");
	
EndProcedure

// See also InfobaseUpdateOverridable.OnDefineSettings
//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithInitialFilling(Objects) Export
	
	Objects.Add(Metadata.Catalogs.WorldCountries);
	Objects.Add(Metadata.Catalogs.ContactInformationKinds);
	
EndProcedure

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	Handlers.Insert("ContactInformationFillingInteractiveCheck", "ContactsManagerInternal.SessionParametersSetting");
EndProcedure

// See AccountingAuditOverridable.OnDefineChecks.
Procedure OnDefineChecks(ChecksGroups, Checks) Export
	
	ChecksGroup = ChecksGroups.Add();
	ChecksGroup.Description                 = NStr("vi = 'Thông tin liên hệ';
													|ru = 'Контактная информация';
													|en = 'Contact information'; fa = 'اطلاعات تماس';
													|it = 'Informazioni di contatto';
													|pl = 'Dane kontaktowe';
													|tr = 'İletişim bilgileri'");
	ChecksGroup.Id                = "ContactInformation";
	ChecksGroup.AccountingChecksContext = "_ContactInformation";
	
	Validation = Checks.Add();
	Validation.GroupID          = "ContactInformation";
	Validation.Description                 = NStr("vi = 'Xác định tùy chỉnh dạng thông tin liên hệ sai';
													|ru = 'Выявление некорректных настроек видов контактной информации';
													|en = 'Identifying incorrect contact information kind settings'; fa = 'Identifying incorrect contact information kind settings';
													|it = 'Rilevazione di impostazioni scorrette dei tipi di informazione di contatto';
													|pl = 'Wykrycie nieodpowiednich ustawień rodzajów danych kontaktowych';
													|tr = 'İletişim bilgileri türleri için yanlış ayarların tespiti'");
	Validation.Reasons                      = NStr("vi = 'Không có trường thông tin liên hệ trong thẻ hoặc chứng từ, hoặc phát sinh trường hợp cản trở công việc với các trường đó.';
													|ru = 'В карточке или документе отсутствуют поля контактной информации, или возникает ситуация, блокирующая работу с ними.';
													|en = 'There are no contact information fields in the card or in the document, or a situation arises that blocks operations with them.'; fa = 'There are no contact information fields in the card or in the document, or a situation arises that blocks operations with them.';
													|it = 'Nella scheda o nel documento mancano i campi di informazione di contatto, o sorge la situazione che blocca il lavoro con tali campi.';
													|pl = 'W karcie lub dokumencie nie ma pola informacji kontaktowej, lub powstaje sytuacja, blokująca pracę z nimi.';
													|tr = 'Kartta veya belgede iletişim bilgileri alanı yok veya bunlarla çalışmayı engelleyen bir durum var.'");
	Validation.Recommendation                 = NStr("vi = 'Thực hiện khôi phục tự động một phần các dạng thông tin liên hệ (để thực hiện việc này, hãy nhấp vào liên kết bên dưới)
	|
	|Nếu làm việc trong cơ sở thông tin phân tán, thì cần khởi chạy bản sửa lỗi trong nút chính.
	|Sau đó đồng bộ hóa với các nút phụ.';
	|ru = 'Выполнить частичное автоматическое восстановление видов контактной информации (для этого нажать ссылку ниже).
	|
	|Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
	|Затем выполнить синхронизацию с подчиненными узлами.';
	|en = 'Perform partial automatic restoration of contact information kinds (to do this, click the link below).
	|
	|For distributed infobases (DIB), run the repair procedure for the master node only.
	|After that, perform synchronization with subordinate nodes.'; fa = 'Perform partial automatic restoration of contact information kinds (to do this, click the link below).
	|
	|For distributed infobases (DIB), run the repair procedure for the master node only.
	|After that, perform synchronization with subordinate nodes.';
	|it = 'Eseguire ripristino automatico parziale dei tipi di informazione di contatto (per farlo premere il link sotto). 
	|
	| Se il lavoro viene eseguito nel database distribuito, la correzione deve essere effettuata solo nel nodo principale.
	| Dopo di che bisogna avviare la sincronizzazione con i nodi subordinati.';
	|pl = 'Wykonaj częściowe przywrócenie automatyczne rodzajów danych kontaktowych (w tym celu naciśnij poniższy odnośnik).
	|
	|Jeśli praca jest prowadzona w rozproszonej bazie informacyjnej (RBI), to korektę należy uruchamiać tylko w węźle głównym.
	|Potem wykonaj synchronizację z węzłami podporządkowanymi.';
	|tr = 'Kişi bilgisi türlerinin kısmi otomatik geri yüklenmesini gerçekleştirin (bunu yapmak için aşağıdaki bağlantıya tıklayın).
	|
	| Dağıtılmış bir bilgi tabanında (DIB) çalışıyorsanız, düzeltme yalnızca ana düğümde çalıştırılmalıdır.
	|Ardından bağımlı düğümlerle senkronize edin.'");
	Validation.Id                = "ContactInformation.CheckAndCorrectContactInformationKinds";
	Validation.HandlerChecks           = "ContactsManagerInternal.CheckContactInformationKinds";
	Validation.GoToCorrectionHandler = "Catalog.ContactInformationKinds.Form.ContactInformationKindsCorrection";
	Validation.AccountingChecksContext = "_ContactInformation";
	Validation.TurnedOff                    = True;
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ModuleAddressManager.OnDefineChecks(ChecksGroups, Checks);
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.ObsoleteAddressesCorrection.Name);
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	NamesAndAliasesMap.Insert("ContactsManagerInternal.ObsoleteAddressesCorrection");
EndProcedure

// See NationalLanguageSupportServer.
Procedure OnDefineObjectsWithTablePresentation(Objects) Export
	Objects.Add("Catalog.ContactInformationKinds");
EndProcedure

Function TheTypesOfContactInformationAreUpdated(Queue) Export
	Return InfobaseUpdate.HasDataLockedByPreviousQueues(Queue, "Catalog.ContactInformationKinds");
EndFunction

#EndRegion

#EndRegion

#Region Private

Function ContainsBlankJSONFields(ObjectToCheck)
	
	MetadataObject = Metadata.FindByType(TypeOf(ObjectToCheck));
	If MetadataObject = Undefined Then
		Return True;
	EndIf;
	
	QueryTemplate = "SELECT TOP 1
		|	TableWithContactInformation.Ref AS Ref
		|FROM
		|	&ObjectWithContactInformationFullName AS TableWithContactInformation
		|WHERE
		|	(CAST(TableWithContactInformation.Value AS STRING(1))) = """"
		|	AND TableWithContactInformation.Ref = &Ref";
	
	QueryTextSet = StrReplace(QueryTemplate, "&ObjectWithContactInformationFullName",
			MetadataObject.FullName() + ".ContactInformation");
			
	Query = New Query(QueryTextSet);
	Query.SetParameter("Ref", ObjectToCheck);
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

Function FillContactInformationJSONFieldsForRef(Ref)
	
	ObjectModified = False;
	
	MetadataObject = Metadata.FindByType(TypeOf(Ref));
	
	Block = New DataLock;
	LockItem = Block.Add(MetadataObject.FullName());
	LockItem.SetValue("Ref", Ref);
	
	BeginTransaction();
	Try
	
		Block.Lock();
		Object = Ref.GetObject();
		Object.Lock();
		
		If FillContactInformationJSONFieldsForObject(Object) Then
			ObjectModified = True;
			Object.Write();
		EndIf;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return ObjectModified;
	
EndFunction

Function FillContactInformationJSONFieldsForObject(ObjectWithContactInformation)
	
	ObjectModified = False;
	
	For Each ContactInformationRow In ObjectWithContactInformation.ContactInformation Do
		
		If ValueIsFilled(ContactInformationRow.Value)
			And ContactsManagerClientServer.IsJSONContactInformation(ContactInformationRow.Value) Then
			Continue;
		EndIf;
		
		If ValueIsFilled(ContactInformationRow.FieldValues) Then
			
			ContactInformationRow.Value = ContactsManager.ContactInformationInJSON(
				ContactInformationRow.FieldValues, ContactInformationRow.Type);
		Else
			
			ContactInformationRow.Value = ContactsByPresentation(
				ContactInformationRow.Presentation, ContactInformationRow.Type);
			
		EndIf;
		
		If ValueIsFilled(ContactInformationRow.Value) Then
			ObjectModified = True;
		EndIf;
		
	EndDo;
	
	Return ObjectModified;

EndFunction

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing) Export
	
	If Not HasRightToAdd() Or Not ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		Return;
	EndIf;
	
	ModuleAddressManager = Common.CommonModule("AddressManager");
	ChoiceData = ModuleAddressManager.FillInAutoSelectionDataByCountry(Parameters);
	StandardProcessing = False;
	
EndProcedure

Procedure AutoCompleteAddress(Val Text, ChoiceData) Export
	
	If Metadata.DataProcessors.Find("AdvancedContactInformationInput") = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = AddressAutoSelectionParameters();
	AdditionalParameters.OnlyWebService = True;
	AdditionalParameters.IsDirectOrder = True;
	
	ModuleAdvancedContactInformationInput = Common.CommonModule("DataProcessors.AdvancedContactInformationInput");
	Result = ModuleAdvancedContactInformationInput.ListOfAutoSelectionLocalities(Text, AdditionalParameters);
	If Result.Cancel Then
		Return;
	EndIf;
	
	ChoiceData = Result.Data;
	FormattingAutoCompleteResults(ChoiceData, Text);
	
EndProcedure

Function AddressAutoSelectionParameters() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("OnlyWebService", False);
	AdditionalParameters.Insert("Levels", "");
	AdditionalParameters.Insert("AddressType", "");
	AdditionalParameters.Insert("IsDirectOrder", False);
	
	Return AdditionalParameters;
	
EndFunction

Procedure FormattingAutoCompleteResults(ChoiceData, Val Text, HighlightOutdatedAddresses = True) Export
	
	If Not ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		Return;
	EndIf;
	
	ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
	
	// Search list appearance.
	SearchTextFragments = StrSplit(Text, " ");
	For Each DataString1 In ChoiceData Do
		
		If TypeOf(DataString1.Value) = Type("Structure")
			And DataString1.Value.Property("Address") Then
			
			If ValueIsFilled(DataString1.Value.Address) And TypeOf(DataString1.Value.Address) = Type("String") Then
				Address = JSONToContactInformationByFields(DataString1.Value.Address, Enums.ContactInformationTypes.Address);
				DataString1.Value.Presentation = ModuleAddressManagerClientServer.AddressPresentation(Address, False);
			EndIf;
			
		EndIf;
		
		Presentation = DataString1.Presentation;
		For Each SearchTextFragment In SearchTextFragments Do
			HighlightedPresentation = StrFindAndHighlightByAppearance(Presentation, SearchTextFragment);
			If HighlightedPresentation <> Undefined Then
				Presentation = HighlightedPresentation;
			EndIf;
		EndDo;
		DataString1.Presentation = Presentation;
		
	EndDo;

EndProcedure

// A function creating the check result.
// 
// Returns:
//   Structure:
//   * ErrorList - ValueList
//   * Result - String
// 
Function CheckResult()
	
	CheckResult = New Structure;
	CheckResult.Insert("Result", "");
	CheckResult.Insert("ErrorList", New ValueList);
	Return CheckResult
	
EndFunction

Function IsAddressType(TypeValue)
	Return Metadata.Enums.ContactInformationTypes.EnumValues.Find(TypeValue) = 
		Metadata.Enums.ContactInformationTypes.EnumValues.Address;
EndFunction

Function CorrectContactInformationKindsBatch(Val ObjectsWithIssues, Validation)
	
	TotalObjectsCorrected = 0; 
	
	QueryText = "SELECT
	|	ObjectsWithIssues.ObjectWithIssue AS Ref
	|INTO ObjectsWithIssues
	|FROM
	| &ObjectsWithIssues AS ObjectsWithIssues
	|INDEX BY
	| ObjectWithIssue
	|;
	|
	|SELECT
	|	ContactInformationKinds.Ref AS Ref,
	|CASE
	|	WHEN ContactInformationKinds.PredefinedKindName <> """"
	|	THEN ContactInformationKinds.PredefinedKindName
	|	ELSE ContactInformationKinds.PredefinedDataName
	|END AS PredefinedKindName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.IsFolder = TRUE
	|;";
	
	MetadataObjects = ObjectsWithContactInformation1();
	QueryTextSet = New Array;
	
	QueryTemplate = "SELECT
	|	MAX(ContactInformation.Ref) AS Ref,
	|	ContactInformation.Kind AS Kind
	|FROM
	|	ObjectsWithIssues AS ObjectsWithIssues
	|		LEFT JOIN &ObjectWithContactInformationFullName AS ContactInformation
	|		ON (ContactInformation.Kind = ObjectsWithIssues.Ref)
	|WHERE
	|	NOT ContactInformation.Ref IS NULL
	|
	|GROUP BY
	|	ContactInformation.Kind";
	
	For Each MetadataObject In MetadataObjects Do
		QueryTextSet.Add(StrReplace(QueryTemplate, "&ObjectWithContactInformationFullName", 
		MetadataObject.Metadata().FullName() + ".ContactInformation"));
	EndDo;
	
	Query = New Query;
	Query.Text = QueryText + StrConcat(QueryTextSet, Chars.LF + " UNION ALL " + Chars.LF);
	Query.Parameters.Insert("ObjectsWithIssues", ObjectsWithIssues);
	
	QueryResults = Query.ExecuteBatch();
	
	GroupNames = QueryResults.Get(1).Unload();
	GroupNames.Indexes.Add("PredefinedKindName");
	
	QueryResult = QueryResults.Get(2);
	
	If QueryResult.IsEmpty() Then
		Return TotalObjectsCorrected;
	EndIf;
	
	QueryString = QueryResult.Select();
	While QueryString.Next() Do
		
		ItemRef = QueryString.Ref;
		FullName = ItemRef.Metadata().FullName();
		
		RowWithNameOfGroup = GroupNames.Find(StrReplace(FullName, ".", ""), "PredefinedKindName"); // CatalogRef.ContactInformationKinds
		If RowWithNameOfGroup <> Undefined Then
			
			BeginTransaction();
			
			Try
				Block = New DataLock;
				LockItem = Block.Add("Catalog.ContactInformationKinds");
				LockItem.SetValue("Ref", QueryString.Kind);
				Block.Lock();
				
				Object = QueryString.Kind.GetObject();
				If Object = Undefined Then
					CommitTransaction();
					Continue;
				EndIf;
				
				LockDataForEdit(QueryString.Kind);
				
				Object.Parent = RowWithNameOfGroup.Ref;
				InfobaseUpdate.WriteData(Object);
				
				TotalObjectsCorrected = TotalObjectsCorrected + 1;
				
				CommitTransaction();
			Except
				RollbackTransaction();
				WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,, 
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				Continue;
			EndTry;
			
			If Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
				ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
				ModuleAccountingAudit.ClearCheckResult(QueryString.Kind, Validation); 
			EndIf;
			
		EndIf;
		
	EndDo;

	Return TotalObjectsCorrected;
	
EndFunction

Function ObjectsWithContactInformation1() Export
	
	MetadataObjects = New Array; // Array of CatalogRef, DocumentRef
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ContactInformationKinds.Ref,
	|CASE
	|	WHEN ContactInformationKinds.PredefinedKindName <> """"
	|	THEN ContactInformationKinds.PredefinedKindName
	|	ELSE ContactInformationKinds.PredefinedDataName
	|END AS PredefinedKindName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.IsFolder = TRUE";
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		If StrStartsWith(SelectionDetailRecords.PredefinedKindName, "Catalog") Then
			ObjectName = Mid(SelectionDetailRecords.PredefinedKindName, StrLen("Catalog") + 1);
			MetadataObjects.Add(Catalogs[ObjectName].EmptyRef());
		ElsIf StrStartsWith(SelectionDetailRecords.PredefinedKindName, "Document") Then
			ObjectName = Mid(SelectionDetailRecords.PredefinedKindName, StrLen("Document") + 1);
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				MetadataObjects.Add(Documents[ObjectName].EmptyRef());
			EndIf;
		EndIf;
	EndDo;
	
	Return MetadataObjects; 

EndFunction

Procedure CorrectContactInformationKindsInBackground(Val CheckParameters, StorageAddress = Undefined) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		Return;
	EndIf;
	
	ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
	Validation = ModuleAccountingAudit.CheckByID(CheckParameters.CheckID);
	
	If Not ValueIsFilled(Validation) Then
		Return;
	EndIf;
	
	SelectionParameters = ModuleAccountingAudit.ParametersOfObjectsWithIssuesSelection();
	ObjectsWithIssues = ModuleAccountingAudit.ObjectsWithIssues(Validation);
	TotalObjectCount      = 0;
	TotalObjectsCorrected = 0;

	While ObjectsWithIssues.Count() > 0 Do
		
		InitialObjectWithIssue = ObjectsWithIssues.Get(ObjectsWithIssues.Count() - 1).ObjectWithIssue;
		TotalObjectCount = TotalObjectCount + ObjectsWithIssues.Count();
		// @skip-check query-in-loop - Batch processing of large amounts of data.
		TotalObjectsCorrected = TotalObjectsCorrected + CorrectContactInformationKindsBatch(ObjectsWithIssues, Validation);
		
		SelectionParameters.InitialObjectWithIssue = InitialObjectWithIssue;
		// @skip-check query-in-loop - Batch processing of large amounts of data.
		ObjectsWithIssues = ModuleAccountingAudit.ObjectsWithIssues(Validation, SelectionParameters);
	
	EndDo;
	Result = New Structure;
	Result.Insert("TotalObjectCount", TotalObjectCount);
	Result.Insert("TotalObjectsCorrected", TotalObjectsCorrected);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Checks and patches incorrect contact information kinds.
//
// Parameters:
//   Validation            - CatalogRef.AccountingCheckRules - a check being executed.
//   CheckParameters   - See AccountingAudit.IssueDetails.CheckParameters
//
Procedure CheckContactInformationKinds(Validation, CheckParameters) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		Return;
	EndIf;
	
	ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
	
	ObjectsToCheck = Undefined;
	CheckParameters.Property("ObjectsToCheck", ObjectsToCheck);
	
	Query = New Query;
	Query.Text = "SELECT
		|	ContactInformationKinds.Ref AS Ref,
		|	ContactInformationKinds.Ref AS Description,
		|CASE
		|	WHEN ContactInformationKinds.PredefinedKindName <> """"
		|	THEN ContactInformationKinds.PredefinedKindName
		|	ELSE ContactInformationKinds.PredefinedDataName
		|END AS PredefinedKindName
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	ContactInformationKinds.IsFolder = FALSE 
		|	AND (ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.EmptyRef)
		|	OR ContactInformationKinds.Parent = UNDEFINED)";
	
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	StringFromQuery = QueryResult.Select();
	
	CheckExecutionParameters = ModuleAccountingAudit.CheckExecutionParameters("ContactInformation", 
		NStr("vi = 'Dạng thông tin liên hệ';
			|ru = 'Виды контактной информации';
			|en = 'Contact information kinds'; fa = 'انواع اطلاعات تماس';
			|it = 'Tipi di informazione di contatto';
			|pl = 'Rodzaje informacji kontaktowej';
			|tr = 'İletişim bilgi türleri'", Common.DefaultLanguageCode()));
	ModuleAccountingAudit.ClearPreviousCheckResults(Validation, CheckExecutionParameters);
	
	CheckKind = ModuleAccountingAudit.CheckKind(CheckExecutionParameters);
	
	While StringFromQuery.Next() Do
		
		If StrStartsWith(StringFromQuery.PredefinedKindName, "Delete") Then
			Continue;
		EndIf;
		
		Issue1 = ModuleAccountingAudit.IssueDetails(StringFromQuery.Ref, CheckParameters);
		Issue1.CheckKind = CheckKind;
		Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền nhóm xác định đối tượng chủ của thông tin liên hệ';
				|ru = 'Не заполнена группа определяющая владельца контактной информации';
				|en = 'The group that determines a contact information owner is required'; fa = 'The group that determines a contact information owner is required';
				|it = 'Il gruppo che determina il titolare dell''informazione di contatto non è compilato.';
				|pl = 'Nie wypełniono grupy określającej właściciela danych kontaktowych';
				|tr = 'İletişim bilgilerinin sahibini tanımlayan grup doldurulmadı'"), StringFromQuery.Description);
		
		ModuleAccountingAudit.WriteIssue(Issue1, CheckParameters);
		
	EndDo;
	
EndProcedure

Procedure ObsoleteAddressesCorrection() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ObsoleteAddressesCorrection);
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ModuleAddressManager.DetectFixObsoleteAddresses();
		
	EndIf;
	
EndProcedure

#Region InfobaseUpdate

Procedure UpdateExistingWorldCountries() Export
	
	If Not ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		Return;
	EndIf;
	
	AllErrors = "";
	Add = False;
	
	Filter = New Structure("Code");
	ModuleAddressManager = Common.CommonModule("AddressManager");
	
	// Cannot perform comparison in the query due to possible database case-insensitivity.
	For Each ClassifierRow In ModuleAddressManager.TableOfClassifier() Do
		Filter.Code = ClassifierRow.Code;
		Selection = Catalogs.WorldCountries.Select(,, Filter);
		CountryFound = Selection.Next();
		If Not CountryFound And Add Then
			Country = Catalogs.WorldCountries.CreateItem();
		ElsIf CountryFound And (
			Selection.Description <> ClassifierRow.Description
			Or Selection.CodeAlpha2 <> ClassifierRow.CodeAlpha2
			Or Selection.CodeAlpha3 <> ClassifierRow.CodeAlpha3
			Or Selection.DescriptionFull <> ClassifierRow.DescriptionFull) Then
			Country = Selection.GetObject();
		Else
			Continue;
		EndIf;
		
		BeginTransaction();
		Try
			If Not Country.IsNew() Then
				LockDataForEdit(Country.Ref);
			EndIf;
			FillPropertyValues(Country, ClassifierRow);
			Country.AdditionalProperties.Insert("DoNotCheckUniqueness");
			Country.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			Info = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể ghi lại quốc gia trên thế giới %1 (mã %2) khi cập nhật bảng phân loại do:
						|%3';
						|ru = 'Невозможно записать страну мира %1 (код %2) при обновлении классификатора по причине:
						|%3';
						|en = 'Couldn''t save ""%1"" (code %2) during the classifier update. Reason:
						|%3'; fa = 'Couldn''t save ""%1"" (code %2) during the classifier update. Reason:
						|%3';
						|it = 'Couldn''t save ""%1"" (code %2) during the classifier update. Reason:
						|%3';
						|pl = 'Couldn''t save ""%1"" (code %2) during the classifier update. Reason:
						|%3';
						|tr = 'Sınıflandırıcı güncellenirken, ülke %1 (kod %2) şu sebeple kaydedilemiyor:
						|%3'"),
				Selection.Code, Selection.Description, ErrorProcessing.BriefErrorDescription(Info));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Error,,,
				ErrorText + Chars.LF + ErrorProcessing.DetailErrorDescription(Info));
			AllErrors = AllErrors + Chars.LF + ErrorText;
		EndTry;
		
	EndDo;
	
	If Not IsBlankString(AllErrors) Then
		Raise TrimAll(AllErrors);
	EndIf;
	
EndProcedure

Procedure UpdatePhoneExtensionSettings() Export
	
	// Sets the PhoneWithExtensionNumber flag for backward compatibility.
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ContactInformationKinds.Ref
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	ContactInformationKinds.Type =  VALUE(Enum.ContactInformationTypes.Phone)";
	
	QueryResult = Query.Execute().Select();
	
	Block = New DataLock();
	Block.Add("Catalog.ContactInformationKinds");
	
	BeginTransaction();
	Try
		
		Block.Lock();
	
		While QueryResult.Next() Do
			ContactInformationKind = QueryResult.Ref.GetObject();
			ContactInformationKind.PhoneWithExtensionNumber = True;
			InfobaseUpdate.WriteData(ContactInformationKind);
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

Procedure SetUsageFlagValue() Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	ContactInformationKinds.Ref AS Ref,
	|	ContactInformationKinds.PredefinedDataName AS PredefinedDataName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	NOT ContactInformationKinds.Used";
	
	Selection = Query.Execute().Select();
	
	Block = New DataLock();
	Block.Add("Catalog.ContactInformationKinds");
	
	BeginTransaction();
	Try
		
		Block.Lock();
		
		While Selection.Next() Do
			
			If StrStartsWith(Upper(Selection.PredefinedDataName), "DELETE") Then
				Continue;
			EndIf;
			
			ObjectContactInformationKind = Selection.Ref.GetObject();
			ObjectContactInformationKind.Used = True;
			InfobaseUpdate.WriteData(ObjectContactInformationKind);
			
		EndDo;
			CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// ContactInformationValidationProcessing event handler
// 
// Parameters:
//   Source - CatalogObject
//            - DocumentObject
//   Cancel - Boolean
//   CheckedAttributes - Array
// 
Procedure ContactInformationValidationProcessing(Source, Cancel, CheckedAttributes) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Not AccessRight("Read", Metadata.Catalogs.ContactInformationKinds) Then
		Return;
	EndIf;
	
	If SessionParameters.ContactInformationFillingInteractiveCheck Then
		SessionParameters.ContactInformationFillingInteractiveCheck = False;
		Return;
	EndIf;
	
	// Contact information is attached to an object.
	Validation = New Structure;
	Validation.Insert("ContactInformation", Undefined);
	Validation.Insert("IsFolder", False);
	FillPropertyValues(Validation, Source);
	
	If Validation.ContactInformation = Undefined Or Validation.IsFolder Then
		Return; // "Contact information" tabular section is missing in the object.
	EndIf;
	
	ContactInformationKinds = RequiredKinds(Source.Ref);
	Messages = New Array;
	
	If ContactInformationKinds.Count() = 0 Then
		Return;
	EndIf;
	
	For Each ContactInformationKind In ContactInformationKinds Do
		Filter = New Structure("Kind", ContactInformationKind);
		FoundRows = Source.ContactInformation.FindRows(Filter);
		
		If FoundRows.Count() = 0 Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString( NStr("vi = 'Chưa điền trường  ""%1"".';
																					|ru = 'Поле ""%1"" не заполнено.';
																					|en = 'Please fill in the ""%1"" field.'; fa = 'Please fill in the ""%1"" field.';
																					|it = 'Il campo ""%1"" non è compilato.';
																					|pl = 'Nie wypełniono pola ""%1"".';
																					|tr = '""%1"" gerekli.'"),
				ContactInformationKind);
			Messages.Add(Text);
			
		Else
			
			For Each ContactInformationRow In FoundRows Do
				
				If IsBlankString(ContactInformationRow.Presentation)
					Or (IsBlankString(ContactInformationRow.Value)
					And IsBlankString(ContactInformationRow.FieldValues)) Then
					
					Text = StringFunctionsClientServer.SubstituteParametersToString( NStr("vi = 'Chưa điền trường  ""%1"".';
																							|ru = 'Поле ""%1"" не заполнено.';
																							|en = 'Please fill in the ""%1"" field.'; fa = 'Please fill in the ""%1"" field.';
																							|it = 'Il campo ""%1"" non è compilato.';
																							|pl = 'Nie wypełniono pola ""%1"".';
																							|tr = '""%1"" gerekli.'"),
						ContactInformationRow.Kind);
					Messages.Add(Text);
					Break;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
		
	If Messages.Count() > 0 Then
		Common.MessageToUser(StrConcat(Messages, Chars.LF),,,, Cancel);
	EndIf;
	
EndProcedure

Function RequiredKinds(ContactInformationOwner)
	
	FullMetadataObjectName = ContactInformationOwner .Metadata().FullName();
	
	CIKindsGroupName = StrReplace(FullMetadataObjectName, ".", "");
	CIKindsGroup = Undefined;
	
	Query = New Query;
	Query.Text = "SELECT
	|	ContactInformationKinds.Ref AS Ref,
	|CASE
	|	WHEN ContactInformationKinds.PredefinedKindName <> """"
	|	THEN ContactInformationKinds.PredefinedKindName
	|	ELSE ContactInformationKinds.PredefinedDataName
	|END AS PredefinedKindName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.IsFolder = TRUE
	|	AND ContactInformationKinds.DeletionMark = FALSE
	|	AND ContactInformationKinds.Used = TRUE";
	
	QueryResult = Query.Execute().Select();
	While QueryResult.Next() Do 
		If StrCompare(QueryResult.PredefinedKindName, CIKindsGroupName) = 0 Then
			CIKindsGroup = QueryResult.Ref;
			Break;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(CIKindsGroup) Then
		Return New Array;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ContactInformationKinds.Ref
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Parent = &CIKindsGroup
	|	AND ContactInformationKinds.DeletionMark = FALSE
	|	AND ContactInformationKinds.Used = TRUE
	|	AND ContactInformationKinds.Mandatory = TRUE";
	
	Query.SetParameter("CIKindsGroup", CIKindsGroup);
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	If ParameterName = "ContactInformationFillingInteractiveCheck" Then
		SessionParameters.ContactInformationFillingInteractiveCheck = False;
		SpecifiedParameters.Add("ContactInformationFillingInteractiveCheck");
	EndIf;
EndProcedure

Procedure SetScheduledJobUsage(Status) Export
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ModuleAddressManager.SetScheduledJobState(Status);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CommonPrivate

Function EventLogEvent() Export
	
	Return NStr("vi = 'Thông tin liên hệ';
				|ru = 'Контактная информация';
				|en = 'Contact information'; fa = 'اطلاعات تماس';
				|it = 'Informazioni di contatto';
				|pl = 'Dane kontaktowe';
				|tr = 'İletişim bilgileri'", Common.DefaultLanguageCode());
	
EndFunction

Function ContactsByPresentation(Presentation, ExpectedKind, SplitByFields = False, RecognizeAddress = True) Export
	
	ExpectedType = ContactsManagerInternalCached.ContactInformationKindType(ExpectedKind);
	
	If ExpectedType = Enums.ContactInformationTypes.Address Then
		
		Return GenerateAddressByPresentation(Presentation, ExpectedKind, SplitByFields, RecognizeAddress);
		
	ElsIf ExpectedType = Enums.ContactInformationTypes.Phone
		Or ExpectedType = Enums.ContactInformationTypes.Fax Then
			Return PhoneFaxDeserializationInJSON("", Presentation, ExpectedType);
		
	Else
		
		ContactInformation = ContactsManagerClientServer.NewContactInformationDetails(ExpectedType);
		ContactInformation.Value = Presentation;
		Return ContactInformation;
		
	EndIf;
	
EndFunction

Function GenerateAddressByPresentation(Presentation, ExpectedKind, SplitByFields = False, RecognizeAddress = True)
	
	HasAddressManagerClientServer = ContactsManagerInternalCached.AreAddressManagementModulesAvailable();
	
	If HasAddressManagerClientServer Then
		ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
		Address = ModuleAddressManagerClientServer.NewContactInformationDetails(Enums.ContactInformationTypes.Address);
		DescriptionMainCountry = TrimAll(Common.ObjectAttributeValue(ModuleAddressManagerClientServer.MainCountry(), "Description"));
	Else
		Address = ContactsManagerClientServer.NewContactInformationDetails(Enums.ContactInformationTypes.Address);
		DescriptionMainCountry = "";
	EndIf;
	
	AnalysisData = AddressPartsAsTable(Presentation);
	If AnalysisData.Count() = 0 Then
		Address.Value = Presentation;
		Return Address;
	EndIf;
	
	DefineCountryAndPostalCode(AnalysisData);
	CountryString = AnalysisData.Find(-2, "Level");
	
	If CountryString = Undefined Then
		Address.Country = DescriptionMainCountry;
	Else
		Address.Country = TrimAll(Upper(CountryString.Value));
	EndIf;
	
	CountryData = ContactsManager.WorldCountryData(, Address.Country);
	If CountryData <> Undefined Then
		Address.countryCode = CountryData.Code;
	EndIf;
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ModuleAddressManager.HandlingFrequentAbbreviationsInAddresses(AnalysisData);
	EndIf;
	
	If Address.Country = DescriptionMainCountry 
	   And Common.SubsystemExists("StandardSubsystems.AddressClassifier") Then
		
		If RecognizeAddress Then
			ModuleAddressClassifierInternal = Common.CommonModule("AddressClassifierInternal");
			AddressOptions = ModuleAddressClassifierInternal.RecognizeAddress(AnalysisData, Presentation, SplitByFields);
		Else
			AddressOptions = Undefined;
		EndIf;
		
		If AddressOptions = Undefined Then
			
			If SplitByFields Then
				
				ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
				If  ModuleAddressManagerClientServer <> Undefined Then
					Address.AddressType = ModuleAddressManagerClientServer.MunicipalAddress();
				EndIf;
				
				Address.Value = Presentation;
				DistributeAddressToFieldsWithoutClassifier(Address, AnalysisData);
				
			Else
				
				Address.Value = Presentation;
				Address.AddressType = ContactsManagerClientServer.CustomFormatAddress();
				
			EndIf;
		Else
			
			FillPropertyValues(Address, AddressOptions);
			If HasAddressManagerClientServer Then
				ModuleAddressManager = Common.CommonModule("AddressManager");
				If ModuleAddressManager <> Undefined Then
					ModuleAddressManager.UpdateAddressPresentation(Address, False);
				EndIf;
			Else
				UpdateAddressPresentation(Address, False);
			EndIf;
			
		EndIf;
			
	Else
		
		If HasAddressManagerClientServer Then
			AddressType = ?(ContactsManager.IsEEUMemberCountry(Address.Country),
				ContactsManagerClientServer.EEUAddress(),
				ContactsManagerClientServer.ForeignAddress());
			Address.AddressType = AddressType;
		Else
			Address.AddressType = ContactsManagerClientServer.CustomFormatAddress();
		EndIf;
		
		IncludeCountryInPresentation = False;
		If TypeOf(ExpectedKind) = Type("CatalogRef.ContactInformationKinds") Then
			IncludeCountryInPresentation = Common.ObjectAttributeValue(ExpectedKind, "IncludeCountryInPresentation");
		EndIf;
		
		NewPresentation = New Array;
		NewStreetPresentation = New Array;
		AnalysisData.Sort("Position");
		For Each AddressPart In AnalysisData Do
			If AddressPart.Level >=0 Then
				NewStreetPresentation.Add(AddressPart.Value);
			EndIf;
				
			If Not IncludeCountryInPresentation And AddressPart.Level = -2 Then
				Continue
			EndIf;
			
			NewPresentation.Add(AddressPart.Value);
		
		EndDo;
		
		Address.value  = StrConcat(NewPresentation, ", ");
		Address.street = StrConcat(NewStreetPresentation, ", ");
		
	EndIf;
	
	If IsBlankString(Address.ZipCode) And Address.AddressType <> ContactsManagerClientServer.CustomFormatAddress() Then
		RowIndex2 = AnalysisData.Find(-1, "Level");
		If RowIndex2 <> Undefined Then
			Address.ZipCode = TrimAll(RowIndex2.Value);
		EndIf;
	EndIf;
	
	Return Address;
	
EndFunction

Procedure UpdateAddressPresentation(Address, IncludeCountryInPresentation)
	
	If TypeOf(Address) <> Type("Structure") Then
		Raise NStr("vi = 'Để tạo trình bày địa chỉ, đã chuyển sai kiểu địa chỉ';
					|ru = 'Для формирования представления адреса передан некорректный тип адреса';
					|en = 'Cannot generate address. Invalid address type passed.'; fa = 'Cannot generate address. Invalid address type passed.';
					|it = 'Per generare la presentazione dell''indirizzo è stato trasmesso il tipo dell''indirizzo scorretto';
					|pl = 'Do tworzenia prezentacji adresu został przekazany nieprawidłowy rodzaj adresu';
					|tr = 'Bir adres görünümü oluşturmak için yanlış adres türü iletildi'");
	EndIf;
	
	FilledLevelsList = New Array;
	
	If IncludeCountryInPresentation And Address.Property("country") And Not IsBlankString(Address.Country) Then
		FilledLevelsList.Add(Address.Country);
	EndIf;
	
	If Address.Property("zipCode") And Not IsBlankString(Address.ZipCode) Then
		FilledLevelsList.Add(Address.ZipCode);
	EndIf;
	
	FilledLevelsList.Add(TrimAll(Address["area"] + " " + Address["areaType"]));
	FilledLevelsList.Add(TrimAll(Address["city"] + " " + Address["cityType"]));
	
	Address.Value = StrConcat(FilledLevelsList, ", ");
	
EndProcedure

Procedure DistributeAddressToFieldsWithoutClassifier(Address, AnalysisData)
	PresentationByAnalysisData = New Array;
	
	For Each AddressPart In AnalysisData Do
		If AddressPart.Level >= 0 Then
			
			If AddressPart.Level = 1 Then
				Address.areaValue = AddressPart.Value;
				Address.area      = AddressPart.Description;
				Address.areaType  = AddressPart.ObjectType;
				Address.munLevels.Add("area");
				Address.admLevels.Add("area");
			Else
				PresentationByAnalysisData.Add(
					ContactsManagerClientServer.ConnectTheNameAndTypeOfTheAddressObject(
					AddressPart.Description, AddressPart.ObjectType));
			EndIf;
		EndIf;
	EndDo;
	
	Address.street = StrConcat(PresentationByAnalysisData, ", ");
	Address.munLevels.Add("street");
	Address.admLevels.Add("street");
	
EndProcedure

// Splits an address string into address lines.
//
// Returns:
//   See AddressParts
//
Function AddressPartsAsTable(Val Text) Export
	
	Result            = AddressParts();
	RegionCode           = Undefined;
	Position                = 1;
	
	BusinessObjectsTypes = BusinessObjectsTypes();
	
	ModuleAddressClassifier = Undefined;
	If Common.SubsystemExists("StandardSubsystems.AddressClassifier") Then
		ModuleAddressClassifier = Common.CommonModule("AddressClassifier");
	EndIf;
	
	SetOfAddressParts = StrSplit(StrReplace(Text, "№", ""), "," + Chars.LF, False);
	
	For Each Term In SetOfAddressParts Do
		Value = TrimAll(Term);
		If IsBlankString(Value) Then
			Continue;
		EndIf;
		
		String = Result.Add();
		String.Level = 0;
		String.Position = Position;
		Position = Position + 1;
		
		If StrFind(Value, " ") = 0 Then
			String.Description = Value;
			String.Value     = Value;
			Continue;
		EndIf;
		
		ValueInUpperCase = Upper(Value);
		FoundType              = False;
		
		For Each BusinessObjectsType In BusinessObjectsTypes Do
			
			// Begins with type
			If StrStartsWith(ValueInUpperCase, BusinessObjectsType.ObjectTypeInBeginning) Then
				Length = BusinessObjectsType.Length;
				String.Description = TrimAll(Mid(Value, Length + 1));
				String.ObjectType   = TrimAll(Left(Value, Length));
				String.Value     = ContactsManagerClientServer.ConnectTheNameAndTypeOfTheAddressObject(String.Description, String.ObjectType);
				FoundType           = True;
				Break;
				
			// Ends with type
			ElsIf StrEndsWith(ValueInUpperCase, BusinessObjectsType.ObjectTypeInEnd) Then
				Length = BusinessObjectsType.Length;
				String.Description = TrimAll(Mid(Value, 1, StrLen(Value) - Length));
				String.ObjectType   = TrimAll(Right(Value, Length));
				String.Value     = ContactsManagerClientServer.ConnectTheNameAndTypeOfTheAddressObject(String.Description, String.ObjectType);
				FoundType           = True;
				Break;
				
			EndIf;
		EndDo;
		
		If Not FoundType Then
			BusinessObjectParts = StrSplit(Value, " ", False);
			If BusinessObjectParts.Count() > 0 Then
				String.ObjectType   = BusinessObjectParts[0];
				BusinessObjectParts.Delete(0);
				String.Description = TrimAll(StrConcat(BusinessObjectParts, " "));
				String.Value     = ContactsManagerClientServer.ConnectTheNameAndTypeOfTheAddressObject(String.Description, String.ObjectType);
			Else
				String.Description = Value;
				String.Value     = Value;
			EndIf;
		EndIf;
		
		If RegionCode = Undefined
		   And ValueIsFilled(String.Value)
		   And ModuleAddressClassifier <> Undefined Then
			RegionCode = ModuleAddressClassifier.RegionCodeByName(String.Value);
			If RegionCode = Undefined Then
				RegionCode = ModuleAddressClassifier.RegionCodeByName(Value);
			EndIf;
			If RegionCode <> Undefined Then
				String.Value = ModuleAddressClassifier.NameOfRegionByCode(RegionCode);
				String.Level  = 1;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// A function creating a table that contains an address where each row is a part of the address.
//
// Returns:
//  ValueTable:
//    * Level - Number
//    * Position - Number
//    * Value - String
//    * Description - String
//    * ObjectType - String
// 
Function AddressParts() Export
	
	StringType = New TypeDescription("String", New StringQualifiers(128));
	NumberType  = New TypeDescription("Number");
	
	Result = New ValueTable;
	Columns = Result.Columns;
	Columns.Add("Level", NumberType);
	Columns.Add("Position", NumberType);
	Columns.Add("Value", StringType);
	Columns.Add("Description", StringType);
	Columns.Add("ObjectType", StringType);

	Return Result;
	
EndFunction

// Returns:
//  ValueTable:
//    * Abbr - String
//    * Length - Number 
//    * AbbreviationInBeginning - String
//    * AbbreviationInEnd - String
//
Function BusinessObjectsTypes()

	
	AbbreviationList = New ValueTable();
	AbbreviationList.Columns.Add("ObjectType",        Common.StringTypeDetails(50));
	AbbreviationList.Columns.Add("Length",             Common.TypeDescriptionNumber(3));
	AbbreviationList.Columns.Add("ObjectTypeInBeginning", Common.StringTypeDetails(20));
	AbbreviationList.Columns.Add("ObjectTypeInEnd",  Common.StringTypeDetails(20));

	Return AbbreviationList;
	
EndFunction

Procedure DefineCountryAndPostalCode(AddressByFields) Export
	
	If Not ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		FieldsSet = AddressByFields.UnloadColumn("Value");
		CountryData = DetermineWorldCountry(FieldsSet);
		If ValueIsFilled(CountryData.Description) Then
			For Each AddressItem In AddressByFields Do
				If StrCompare(CountryData.Description, AddressItem.Value) = 0 Then
					AddressItem.Level = -2;
				EndIf;
			EndDo;
		EndIf;
		Return;
	EndIf;
	
	TypeDescriptionNumber = New TypeDescription("Number");
	ModuleAddressManager = Common.CommonModule("AddressManager");
	Classifier = ModuleAddressManager.TableOfClassifier();
	
	For Each AddressItem In AddressByFields Do
		IndexOf = TypeDescriptionNumber.AdjustValue(AddressItem.Description);
		If IndexOf >= 100000 And IndexOf < 1000000 Then
			AddressItem.Level = -1;
		Else
			CountryByClassifier = Classifier.Find(Upper(AddressItem.Value), "Description");
			ContactsManagerLocalization.OnCheckCountryAfterCountrySearchInClassifier(CountryByClassifier);
			If CountryByClassifier <> Undefined Then
				AddressItem.Level = -2;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function DetermineWorldCountry(AddressByFields) Export
	
	Result = New Structure();
	Result.Insert("Ref",       Undefined);
	Result.Insert("Description", "");
	Result.Insert("CountryCode",    "");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	WorldCountries.Ref AS Ref,
		|	WorldCountries.Description AS Description,
		|	WorldCountries.Code AS CountryCode
		|FROM
		|	Catalog.WorldCountries AS WorldCountries
		|WHERE
		|	WorldCountries.Description IN(&FieldsSet)";
		
	Query.SetParameter("FieldsSet", AddressByFields);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	CountryInformation_ = QueryResult.Select();
	
	If CountryInformation_.Next() Then
		FillPropertyValues(Result, CountryInformation_);
		Return Result;
	EndIf;
	
	Return Result;
	
EndFunction

Function ContactInformationPresentation(Val ContactInformation, Transliterate = False) Export
	
	If IsBlankString(ContactInformation) Then
		Return "";
	EndIf;
	
	If ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		
		ContactInformation = JSONToContactInformationByFields(ContactInformation, Undefined);
		
	ElsIf TypeOf(ContactInformation) = Type("Structure") Then
		
		If ContactInformation.Property("PhoneNumber") Then
			ContactInformationType = Enums.ContactInformationTypes.Phone;
		Else
			ContactInformationType = Enums.ContactInformationTypes.Address;
		EndIf;
		
		ContactInformation = ContactInformationToJSONStructure(ContactInformation, ContactInformationType);
		
	ElsIf TypeOf(ContactInformation) = Type("String") Or TypeOf(ContactInformation) = Type("XDTODataObject") Then
		
		ContactInformation = ContactInformationToJSONStructure(ContactInformation);
		
	EndIf;
	
	If IsBlankString(ContactInformation.Value) Then
		GenerateContactInformationPresentation(ContactInformation, Undefined);
	EndIf;
	
	If TypeOf(Transliterate) = Type("Boolean") And Transliterate Then
		Return StringFunctions.LatinString(ContactInformation.Value);
	EndIf;
	
	Return ContactInformation.Value;
	
EndFunction

Function AddressEnteredInFreeFormat(Val ContactInformation) Export
	
	If ContactsManagerClientServer.IsXMLContactInformation(ContactInformation) Then
		JSONContactInformation = ContactsManager.ContactInformationInJSON(ContactInformation);
		ContactInformation = JSONToContactInformationByFields(JSONContactInformation, Enums.ContactInformationTypes.Address);
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
		ContactInformation = JSONToContactInformationByFields(ContactInformation, Enums.ContactInformationTypes.Address);
	EndIf;
	
	If TypeOf(ContactInformation) = Type("Structure")
		And ContactInformation.Property("AddressType") Then
			Return ContactsManagerClientServer.IsAddressInFreeForm(ContactInformation.AddressType);
	EndIf;
	
	Return False;
	
EndFunction

Function GenerateContactInformationPresentation(Val Information, Val InformationKind)
	
	If TypeOf(Information) = Type("String") And ContactsManagerClientServer.IsJSONContactInformation(Information) Then
		ContactInformationType = Common.ObjectAttributeValue(InformationKind, "Type");
		Information = JSONToContactInformationByFields(Information, ContactInformationType);
	EndIf;
	
	If TypeOf(Information) = Type("Structure") Then
		
		If IsAddressType(Information.Type) Then
			Return AddressPresentation(Information, InformationKind);
			
		ElsIf Information.Type = String(Enums.ContactInformationTypes.Phone)
			Or Information.Type = String(Enums.ContactInformationTypes.Fax) Then
			PhonePresentation = PhonePresentation(Information);
			Return ?(IsBlankString(PhonePresentation), Information.Value, PhonePresentation);
		EndIf;
		
		Return Information.Value;
	EndIf;
	
	Return GenerateContactInformationPresentation(ContactInformationToJSONStructure(Information), InformationKind);
	
EndFunction

Function IsNationalAddress(Val Address) Export
	
	If Not ValueIsFilled(Address) Then
		Return False;
	EndIf;
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		
		If TypeOf(Address) = Type("String") Then
			Address = JSONToContactInformationByFields(Address, Enums.ContactInformationTypes.Address);
		EndIf;
		
		If TypeOf(Address) = Type("Structure") And Address.Property("Country")Then
			
			ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
			CountryDescription = Common.ObjectAttributeValue(ModuleAddressManagerClientServer.MainCountry(), "Description");
			Return StrCompare(CountryDescription, Address.Country) = 0;
			
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

Function AddressPresentation(Val Address, Val InformationKind)
	
	If TypeOf(InformationKind) = Type("Structure") And InformationKind.Property("IncludeCountryInPresentation") Then
		IncludeCountryInPresentation = InformationKind.IncludeCountryInPresentation;
	Else
		IncludeCountryInPresentation = False;
	EndIf;
	
	If TypeOf(Address) = Type("Structure") Then
		
		If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
			ModuleAddressManager = Common.CommonModule("AddressManager");
			ModuleAddressManager.UpdateAddressPresentation(Address, IncludeCountryInPresentation);
		Else
			UpdateAddressPresentation(Address, IncludeCountryInPresentation);
		EndIf;
		
		Return Address.Value;
	Else
		Presentation = TrimAll(Address);
		
		If StrOccurrenceCount(Presentation, ",") = 9 Then
			PresentationAsArray = StrSplit(Presentation, ",", False);
			If PresentationAsArray.Count() > 0 Then
				For IndexOf = 0 To PresentationAsArray.UBound() Do
					PresentationAsArray[IndexOf] = TrimAll(PresentationAsArray[IndexOf]);
				EndDo;
				PresentationAsArray.Delete(0); // Remove the country.
				Presentation = StrConcat(PresentationAsArray, ", ");
			EndIf;
		EndIf;
	EndIf;
	
	Return Presentation;
	
EndFunction

Function PhonePresentation(PhoneData) Export
	
	If TypeOf(PhoneData) = Type("Structure") Then
		
		PhonePresentation = ContactsManagerClientServer.GeneratePhonePresentation(
			RemoveNonDigitCharacters(PhoneData.countryCode),
			PhoneData.areaCode,
			PhoneData.number,
			PhoneData.extNumber,
			"");
			
	Else
		
		PhonePresentation = ContactsManagerClientServer.GeneratePhonePresentation(
			RemoveNonDigitCharacters(PhoneData.CountryCode), 
			PhoneData.CityCode,
			PhoneData.Number,
			PhoneData.PhoneExtension,
			"");
		
	EndIf;
	
	Return PhonePresentation;
	
EndFunction

// Parameters:
//  Source - CatalogRef.ContactInformationKinds
//           - Structure
//           - Undefined
// Returns:
//  Structure:
//    * Ref - CatalogRef.ContactInformationKinds
//             - Undefined
//    * Error - Boolean
//    * ErrorDescription - String
// 
Function ContactInformationKindStructure(Val Source = Undefined) Export
	
	Metadata_Attributes = Metadata.Catalogs.ContactInformationKinds.Attributes;
	
	If TypeOf(Source) = Type("CatalogRef.ContactInformationKinds") Then
		Attributes = "Description";
		For Each AttributeMetadata In Metadata_Attributes Do
			Attributes = Attributes + "," + AttributeMetadata.Name;
		EndDo;
		
		Result = Common.ObjectAttributesValues(Source, Attributes);
	Else
		Result = New Structure("Description", "");
		For Each AttributeMetadata In Metadata_Attributes Do
			Result.Insert(AttributeMetadata.Name, AttributeMetadata.Type.AdjustValue());
		EndDo;
		
		If Source <> Undefined Then
			FillPropertyValues(Result, Source);
			
			If Source.Property("ValidationSettings") And Source.ValidationSettings <> Undefined Then
				FillPropertyValues(Result, Source.ValidationSettings);
			EndIf;
		EndIf;
		
	EndIf;
	Result.Insert("Ref", Source);
	
	Return Result;
	
EndFunction

Function ContactInformationKindsData(Val ContactInformationKinds) Export
	
	Metadata_Attributes = Metadata.Catalogs.ContactInformationKinds.Attributes;
	Attributes = "Description, PredefinedDataName, DeletionMark";
	For Each AttributeMetadata In Metadata_Attributes Do
		Attributes = Attributes + "," + AttributeMetadata.Name;
	EndDo;
	
	Return Common.ObjectsAttributesValues(ContactInformationKinds, Attributes);
	
EndFunction

// Parameters:
//   Object - CatalogObject
///
Procedure UpdateCotactsForListsForObject(Object) Export
	
	ContactInformation = Object.ContactInformation;
	
	If ContactInformation.Count() = 0 Then
		Return;
	EndIf;
	
	IndexOf = ContactInformation.Count() - 1;
	While IndexOf >= 0 Do
		If Not ValueIsFilled(ContactInformation[IndexOf].Kind) Then
			ContactInformation.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf -1;
	EndDo;
	
	ColumnValidFromMissing = Not ContactsManagerInternalCached.ObjectContactInformationContainsValidFromColumn(Object.Ref);
	
	Query = New Query("SELECT
		|	ContactInformation.Presentation AS Presentation,
		|	ContactInformation.LineNumber AS LineNumber,
		|	ContactInformation.Kind AS Kind" + ?(ColumnValidFromMissing, "", ", ContactInformation.ValidFrom AS ValidFrom") + "
		|INTO ContactInformation
		|FROM
		|	&ContactInformation AS ContactInformation
		|;");//@query-part
	
	If ColumnValidFromMissing Then
		Query.Text = Query.Text + "SELECT
		|	ContactInformation.Presentation AS Presentation,
		|	ContactInformation.Kind AS Kind,
		|	ContactInformation.LineNumber AS LineNumber,
		|	COUNT(ContactInformation.Kind) AS Count
		|FROM
		|	ContactInformation AS ContactInformation
		|
		|GROUP BY
		|	ContactInformation.Kind,
		|	ContactInformation.LineNumber,
		|	ContactInformation.Presentation
		|ORDER BY
		|	LineNumber
		|TOTALS BY
		|	Kind";
	Else
		Query.Text = Query.Text + "SELECT
		|	ContactInformation.Kind AS Kind,
		|	MAX(ContactInformation.ValidFrom) AS ValidFrom
		|INTO LatestContactInformation
		|FROM
		|	ContactInformation AS ContactInformation
		|
		|GROUP BY
		|	ContactInformation.Kind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ContactInformation.Presentation AS Presentation,
		|	ContactInformation.Kind AS Kind,
		|	ContactInformation.ValidFrom AS ValidFrom,
		|	ISNULL(ContactInformation.LineNumber, 0) AS LineNumber,
		|	COUNT(ContactInformation.Kind) AS Count
		|FROM
		|	LatestContactInformation AS LatestContactInformation
		|		LEFT JOIN ContactInformation AS ContactInformation
		|		ON LatestContactInformation.ValidFrom = ContactInformation.ValidFrom
		|			AND LatestContactInformation.Kind = ContactInformation.Kind
		|
		|GROUP BY
		|	ContactInformation.Kind,
		|	ContactInformation.Presentation,
		|	ContactInformation.ValidFrom,
		|	ContactInformation.LineNumber
		|ORDER BY
		|	LineNumber
		|TOTALS BY
		|	Kind, ValidFrom";
	EndIf;
	
	Query.SetParameter("ContactInformation", ContactInformation.Unload());
	QueryResult = Query.Execute();
	SelectionKind       = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionKind.Next() Do
		SelectionDetailRecords = SelectionKind.Select();
		If SelectionKind.Count = 1 Then
			If ColumnValidFromMissing Then
				TablesRow = ContactInformation.Find(SelectionKind.Kind, "Kind");
				TablesRow.KindForList = SelectionKind.Kind;
			Else
				ValidFrom = Date(1,1,1);
				While SelectionDetailRecords.Next() Do
					If ValueIsFilled(SelectionDetailRecords.ValidFrom) Then
						ValidFrom = SelectionDetailRecords.ValidFrom;
					EndIf;
				EndDo;
				FoundRows = ContactInformation.FindRows(New Structure("Kind", SelectionKind.Kind));
				For Each RowWithContactInformation In FoundRows Do
					RowWithContactInformation.KindForList = ?(RowWithContactInformation.ValidFrom = ValidFrom,
							SelectionKind.Kind, Catalogs.ContactInformationKinds.EmptyRef());
				EndDo;
			EndIf;
		ElsIf SelectionKind.Count > 1 Then
			FoundRows = ContactInformation.FindRows(New Structure("Kind", SelectionKind.Kind));
			For Each RowWithContactInformation In FoundRows Do
				RowWithContactInformation.KindForList = Undefined;
			EndDo;

			ContactInformationItems = New Array;
			While SelectionDetailRecords.Next() Do
				If ValueIsFilled(SelectionDetailRecords.Presentation) Then
					ContactInformationItems.Add(SelectionDetailRecords.Presentation);
				EndIf;
			EndDo;
			TablesRow               = ContactInformation.Add();
			TablesRow.KindForList  = SelectionKind.Kind;
			TablesRow.Presentation = StrConcat(ContactInformationItems, ", ");
		EndIf;
	EndDo;
	
EndProcedure

Procedure UpdateContactInformationForLists() Export
	
	ObjectsWithKindForListColumn = ObjectsContainingKindForList();
	
	For Each ObjectRef In ObjectsWithKindForListColumn Do
		
		Block = New DataLock;
		LockItem = Block.Add(Metadata.FindByType(TypeOf(ObjectRef)).FullName());
		LockItem.SetValue("Ref", ObjectRef);
		
		BeginTransaction();
		Try
			
			Block.Lock();
		
			Object = ObjectRef.GetObject();
			ContactInformation = Object.ContactInformation;
			
			Filter = New Structure("Type", Enums.ContactInformationTypes.EmptyRef());
			RowsForDeletion = ContactInformation.FindRows(Filter);
			For Each RowForDeletion In RowsForDeletion Do
				ContactInformation.Delete(RowForDeletion);
			EndDo;
			
			Query = New Query;
			Query.Text = 
				"SELECT
				|	ContactInformation.Presentation AS Presentation,
				|	ContactInformation.Kind AS Kind
				|INTO ContactInformation
				|FROM
				|	&ContactInformation AS ContactInformation
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ContactInformation.Presentation AS Presentation,
				|	ContactInformation.Kind AS Kind,
				|	COUNT(ContactInformation.Kind) AS Count
				|FROM
				|	ContactInformation AS ContactInformation
				|
				|GROUP BY
				|	ContactInformation.Kind,
				|	ContactInformation.Presentation TOTALS BY Kind";
			
			Query.SetParameter("ContactInformation", ContactInformation);
			QueryResult = Query.Execute(); // @skip-check query-in-loop - Queries to different tables.
			SelectionKind = QueryResult.Select(QueryResultIteration.ByGroups);
			
			While SelectionKind.Next() Do
				SelectionDetailRecords = SelectionKind.Select();
				If SelectionKind.Count = 1 Then
					TablesRow = ContactInformation.Find(SelectionKind.Kind, "Kind");
					TablesRow.KindForList = SelectionKind.Kind;
				ElsIf SelectionKind.Count > 1 Then
					TablesRow = ContactInformation.Add();
					TablesRow.KindForList = SelectionKind.Kind;
					Separator   = "";
					Presentation = "";
					While SelectionDetailRecords.Next() Do
						Presentation = Presentation +Separator + SelectionDetailRecords.Presentation;
						Separator = ", ";
					EndDo;
					TablesRow.Presentation = Presentation;
				EndIf;
			EndDo;
			InfobaseUpdate.WriteData(Object);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
		EndTry;
		
	EndDo;

EndProcedure

Function ObjectsContainingKindForList()
	
	MetadataObjects = New Array; // Array of CatalogRef, DocumentRef
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ContactInformationKinds.Ref,
	|CASE
	|	WHEN ContactInformationKinds.PredefinedKindName <> """"
	|	THEN ContactInformationKinds.PredefinedKindName
	|	ELSE ContactInformationKinds.PredefinedDataName
	|END AS PredefinedKindName
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.IsFolder = TRUE";
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		If StrStartsWith(SelectionDetailRecords.PredefinedKindName, "Catalog") Then
			ObjectName = Mid(SelectionDetailRecords.PredefinedKindName, StrLen("Catalog") + 1);
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then 
				ContactInformation = Metadata.Catalogs[ObjectName].TabularSections.ContactInformation;
				If ContactInformation.Attributes.Find("KindForList") <> Undefined Then
					MetadataObjects.Add(Catalogs[ObjectName].EmptyRef());
				EndIf;
			EndIf;
		ElsIf StrStartsWith(SelectionDetailRecords.PredefinedKindName, "Document") Then
			ObjectName = Mid(SelectionDetailRecords.PredefinedKindName, StrLen("Document") + 1);
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				ContactInformation = Metadata.Documents[ObjectName].TabularSections.ContactInformation;
				If ContactInformation.Attributes.Find("KindForList") <> Undefined Then
					MetadataObjects.Add(Documents[ObjectName].EmptyRef());
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	QueryTextSet = New Array;
	QueryTemplate = "SELECT
		|	ContactInformation.Ref AS Ref
		|FROM
		|	#ContactInformationOfTheMetadataObject AS ContactInformation
		|WHERE
		|	ContactInformation.Kind <> VALUE(Catalog.ContactInformationKinds.EmptyRef)
		|
		|GROUP BY
		|	ContactInformation.Ref
		|
		|HAVING
		|	COUNT(ContactInformation.Kind) > 0 ";
	
	For Each Object In MetadataObjects Do
		QueryTextSet.Add(StrReplace(QueryTemplate, 
			"#ContactInformationOfTheMetadataObject",
			"Catalog." +  Object.Metadata().Name + ".ContactInformation"));
	EndDo;
	
	Query = New Query;
	Query.Text = StrConcat(QueryTextSet, " UNION ALL ");
	QueryResult = Query.Execute().Unload().UnloadColumn("Ref");

	Return QueryResult;

EndFunction

// Details
// 
// Parameters:
//   ContactInformationKind - FormDataStructure
//                           - CatalogObject.ContactInformationKinds:
//     * Description - String
//     * Type  - EnumRef.ContactInformationTypes
// 	 
// Returns:
//   Structure:
//   * HasErrors - Boolean
//   * ErrorText - String
// 
Function CheckContactsKindParameters(ContactInformationKind) Export
	
	Result = New Structure("HasErrors, ErrorText", False, "");
	
	If Not ValueIsFilled(ContactInformationKind.Description) Then
		Result.HasErrors = True;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền trường bắt buộc Tên gọi trong dạng thông tin liên hệ ""%1"".';
				|ru = 'Не заполнено обязательное поле Наименование у вида контактной информации ""%1"".';
				|en = 'Field ""Description"" of the ""%1"" contact information kind is empty. The field is required.'; fa = 'Field ""Description"" of the ""%1"" contact information kind is empty. The field is required.';
				|it = 'Campo obbligatorio Denominazione per il tipo di informazioni di contatto ""%1"" non compilato.';
				|pl = 'Nie jest wypełnione pole wymagane Nazwa gatunku, dane kontaktowe ""%1"".';
				|tr = '""%1"" iletişim bilgilerinin türü için gerekli alan Tanımı doldurulmadı.'"),
			String(ContactInformationKind.PredefinedKindName));
		Return Result;
	EndIf;
	
	If ContactInformationKind.IsFolder Then
		Return Result;
	EndIf;
	
	If Not ValueIsFilled(ContactInformationKind.Type) Then
		Result.HasErrors = True;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền trường bắt buộc Kiểu trong dạng thông tin liên hệ ""%1"".';
				|ru = 'Не заполнено обязательное поле Тип у вида контактной информации ""%1"".';
				|en = 'Field ""Type"" of the ""%1"" contact information kind is empty. The field is required.'; fa = 'Field ""Type"" of the ""%1"" contact information kind is empty. The field is required.';
				|it = 'Campo obbligatorio Tipo per il tipo di informazioni di contatto ""%1"" non compilato.';
				|pl = 'Nie jest wypełnione pole wymagane Typ w rodzaju informacji kontaktowych ""%1"".';
				|tr = 'İletişim bilgileri türündeki zorunlu tip ""%1"" alanı doldurulmamıştır.'"),
			String(ContactInformationKind.Description));
		Return Result;
	EndIf;
	
	Separator = "";
	If ContactInformationKind.Type = Enums.ContactInformationTypes.Address Then
		
		If Not ContactInformationKind.OnlyNationalAddress
			And (ContactInformationKind.CheckValidity
			Or ContactInformationKind.HideObsoleteAddresses) Then
				Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã điền sai tùy chỉnh kiểm tra địa chỉ trong dạng thông tin liên hệ%1.
					|Chỉ có thể kiểm tra tính chính xác của địa chỉ';
					|ru = 'Некорректно заполнены настройки проверки адреса у вида контактной информации %1.
					| Проверка корректности адреса доступна только для российских адресов';
					|en = 'Invalid address validation settings for the %1 contact information kind.
					|Validation for this kind is not available.'; fa = 'Invalid address validation settings for the %1 contact information kind.
					|Validation for this kind is not available.';
					|it = 'Le configurazioni della verifica di indirizzo del tipo dell''informazione di contatto %1 sono compilate nel modo scorretto.
					| La verifica della correttezza dell''indirizzo è disponibile solo per indirizzi russi';
					|pl = 'Są niepoprawnie wypełnione ustawienia weryfikacji adresu u rodzaju informacji kontaktowych %1.
					| Weryfikacja poprawności adresów jest dostępna tylko dla rosyjskich adresów';
					|tr = 'İletişim bilgileri görünümünde adres doğrulama ayarları yanlış dolduruldu%1 . 
					|Adres doğruluğu doğrulama sadece Rus adresleri için kullanılabilir'"), 
					String(ContactInformationKind.Description));
					Separator = Chars.LF;
			EndIf;
			
		If ContactInformationKind.AllowMultipleValueInput
			And ContactInformationKind.StoreChangeHistory Then
				Result.ErrorText = Result.ErrorText + Separator 
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đã điền sai tùy chỉnh địa chỉ trong dạng thông tin liên hệ %1.
						| Không cho phép nhập nhiều giá trị thông tin liên hệ khi bật lịch sử lưu thay đổi.';
						|ru = 'Некорректно заполнены настройки адреса у вида контактной информации %1.
						| Не допускается возможность ввода нескольких значений контактной информации при включенной истории хранения изменений.';
						|en = 'Invalid address settings for the %1 contact information kind.
						|Contact information does not support multiple entry if the Change history feature is selected.'; fa = 'Invalid address settings for the %1 contact information kind.
						|Contact information does not support multiple entry if the Change history feature is selected.';
						|it = 'Le configurazioni dell''indirizzo del tipo dell''informazione di contatto %1 sono compilate nel modo scorretto.
						| Non è ammessa la possibilità di immissione di più valori dell''informazione di contatto se la storia di stoccaggio modifiche è attiva.';
						|pl = 'Są niepoprawnie wypełnione ustawienia adresu u rodzaju informacji kontaktowych %1.
						| Nie dopuszcza się możliwość wprowadzania wielu wartości informacji kontaktowych przy włączonej historii przechowywania zmian.';
						|tr = 'İletişim bilgileri görünümünde adres ayarları yanlış dolduruldu%1 .
						| Değişiklik depolama geçmişi etkin olduğunda birden çok iletişim bilgileri değerleri girmek için izin verilmez.'"),
						String(ContactInformationKind.Description));
		EndIf;
	EndIf;
	
	Result.HasErrors = ValueIsFilled(Result.ErrorText);
	Return Result;
	
EndFunction

Function HasRightToAdd() Export
	Return AccessRight("Insert", Metadata.Catalogs.WorldCountries);
EndFunction

Procedure AddContactInformationForRef(Ref, ValueOrPresentation, ContactInformationKind, 
	Date = Undefined, Replace = True, RecognizeAddress = True) Export
	
	MetadataObject = Metadata.FindByType(TypeOf(Ref));
	
	Block = New DataLock;
	LockItem = Block.Add(MetadataObject.FullName());
	LockItem.SetValue("Ref", Ref);
	
	BeginTransaction();
	Try
	
		Block.Lock();
		Object = Ref.GetObject();
		Object.Lock();
		AddContactInformation(Object, ValueOrPresentation, ContactInformationKind, Date, Replace, 
			RecognizeAddress);
		
		Object.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Parameters:
//   Object - CatalogObject
//   ValueOrPresentation - String
//   ContactInformationKind - CatalogRef.ContactInformationKinds
//   Date - Undefined
//   Replace - Boolean
// 
Procedure AddContactInformation(Object, ValueOrPresentation, ContactInformationKind, Val Date, Val Replace, RecognizeAddress = True) Export
	
	ContactInformation                  = Object.ContactInformation;
	IsXMLContactInformation           = ContactsManagerClientServer.IsXMLContactInformation(ValueOrPresentation);
	IsJSONContactInformation          = ContactsManagerClientServer.IsJSONContactInformation(ValueOrPresentation);
	IsContactInformationInJSONStructure = TypeOf(ValueOrPresentation) = Type("Structure");
	ContactInformationKindProperties      = Common.ObjectAttributesValues(ContactInformationKind, 
		"Type, StoreChangeHistory");
	
	ObjectMetadata = Metadata.FindByType(TypeOf(Object));
	If ObjectMetadata = Undefined
		Or ObjectMetadata.TabularSections.Find("ContactInformation") = Undefined Then
		Raise NStr("vi = 'Không thể thêm thông tin liên hệ, trong đối tượng không có bảng với thông tin liên hệ.';
					|ru = 'Добавление контактной информации невозможно, у объекта нет таблицы с контактной информацией.';
					|en = 'Cannot add contact information. The object does not have a contact information table.'; fa = 'Cannot add contact information. The object does not have a contact information table.';
					|it = 'Impossibile aggiungere le informazioni di contatto, l''oggetto non possiede la tabella con le informazioni di contatto.';
					|pl = 'Dodawanie informacji kontaktowych nie jest możliwe, obiekt nie ma tabeli z danymi kontaktowymi.';
					|tr = 'İletişim bilgileri eklenemiyor. Nesnenin iletişim bilgileri tablosu yok.'");
	EndIf;
	
	If IsContactInformationInJSONStructure Then
		
		ObjectOfContactInformation = ValueOrPresentation;
		Value = ToJSONStringStructure(ValueOrPresentation);
		FieldValues = ContactsManager.ContactInformationToXML(Value);
		Presentation = ObjectOfContactInformation.Value;
		
	Else
		
		If IsXMLContactInformation Then
			
			FieldValues = ValueOrPresentation;
			Value = ContactsManager.ContactInformationInJSON(ValueOrPresentation, 
				ContactInformationKindProperties.Type);
			ObjectOfContactInformation = JSONToContactInformationByFields(Value, 
				ContactInformationKindProperties.Type);
			Presentation = ObjectOfContactInformation.Value;
			
		ElsIf IsJSONContactInformation Then
			
			Value = ValueOrPresentation;
			FieldValues = ContactsManager.ContactInformationToXML(Value,, 
				ContactInformationKindProperties.Type);
			ObjectOfContactInformation = JSONToContactInformationByFields(Value, 
				ContactInformationKindProperties.Type);
			Presentation = ContactInformationPresentation(ValueOrPresentation);
			
		Else
			ObjectOfContactInformation = ContactsByPresentation(ValueOrPresentation, 
				ContactInformationKindProperties.Type, ,RecognizeAddress);
			Value = ToJSONStringStructure(ObjectOfContactInformation);
			FieldValues = ContactsManager.ContactInformationToXML(Value);
			Presentation = ValueOrPresentation;
			
		EndIf;
		
	EndIf;
	
	Periodic = ContactsManagerInternalCached.ObjectContactInformationContainsValidFromColumn(Object.Ref);
	If Replace Then
		FoundRows = FindContactInformationStrings(ContactInformationKind, Date, ContactInformation, Periodic);
		For Each LineOfATabularSection In FoundRows Do
			ContactInformation.Delete(LineOfATabularSection);
		EndDo;
		ContactInformationRow = ContactInformation.Add();
	Else
		If MultipleValuesInputProhibited(ContactInformationKind, ContactInformation, Date, Periodic) Then
			If IsXMLContactInformation Then
				ContactInformationRow = Object.ContactInformation.Find(ValueOrPresentation, "FieldValues");
			ElsIf IsJSONContactInformation Then
				ContactInformationRow = Object.ContactInformation.Find(ValueOrPresentation, "Value");
			Else
				ContactInformationRow = Object.ContactInformation.Find(ValueOrPresentation, "Presentation");
			EndIf;
			If ContactInformationRow <> Undefined Then
				Return; // Only one value of this contact information kind is allowed.
			EndIf;
		EndIf;
		ContactInformationRow = ContactInformation.Add();
	EndIf;
	
	ContactInformationRow.Value      = Value;
	ContactInformationRow.Presentation = Presentation;
	ContactInformationRow.FieldValues = FieldValues;
	ContactInformationRow.Kind           = ContactInformationKind;
	ContactInformationRow.Type           = ContactInformationKindProperties.Type ;
	If ContactInformationKindProperties.StoreChangeHistory And ValueIsFilled(Date) Then
		ContactInformationRow.ValidFrom = Date;
	EndIf;
	
	FillContactInformationTechnicalFields(ContactInformationRow, ObjectOfContactInformation, 
		ContactInformationKindProperties.Type);
	
EndProcedure

// Parameters:
//   Object - CatalogObject
//   ContactInformation - ValueTable
//   MetadataObject - MetadataObject
//   Replace - Boolean
// 
Procedure SetObjectContactInformation(Object, ContactInformation, MetadataObject, Val Replace) Export
	
	Periodic = ContactsManagerInternalCached.ObjectContactInformationContainsValidFromColumn(Object.Ref);
	WithoutTabularSectionID = MetadataObject.TabularSections.ContactInformation.Attributes.Find("TabularSectionRowID") = Undefined;
	
	For Each ContactInformationRow In ContactInformation Do
		ContactsManager.RestoreEmptyValuePresentation(ContactInformationRow);
	EndDo;
	
	If Replace Then
		
		For Each ObjectContactInformationRow In ContactInformation Do
			
			FilterDate = ?(Periodic, ObjectContactInformationRow.Date, Undefined);
			ContactInformationRows = FindContactInformationStrings(ObjectContactInformationRow.Kind, 
				FilterDate, Object.ContactInformation, Periodic);
			For Each TableRow In ContactInformationRows Do
				Object.ContactInformation.Delete(TableRow);
			EndDo;
		EndDo;
		
	EndIf;
	
	For Each ObjectContactInformationRow In ContactInformation Do
		
		StoreChangeHistory = Periodic And ObjectContactInformationRow.Kind.StoreChangeHistory;
		
		If Replace Then
			
			TabularSectionRowID = ?(WithoutTabularSectionID, Undefined, 
				ObjectContactInformationRow.TabularSectionRowID);
			If MultipleValuesInputProhibited(ObjectContactInformationRow.Kind, Object.ContactInformation, 
				ObjectContactInformationRow.Date, StoreChangeHistory, TabularSectionRowID) Then
				Continue;
			EndIf;
			ContactInformationRow = Object.ContactInformation.Add();
			
		Else
			
			Filter = New Structure();
			Filter.Insert("Kind", ObjectContactInformationRow.Kind);
			
			If StoreChangeHistory Then
				Filter.Insert("ValidFrom", ObjectContactInformationRow.Date);
				ContactInformationRows = Object.ContactInformation.FindRows(Filter);
			ElsIf ValueIsFilled(ObjectContactInformationRow.Value) Then
				Filter.Insert("Value", ObjectContactInformationRow.Value);
				ContactInformationRows = Object.ContactInformation.FindRows(Filter);
			Else
				Filter.Insert("FieldValues", ObjectContactInformationRow.FieldValues);
				ContactInformationRows = Object.ContactInformation.FindRows(Filter);
			EndIf;
			
			If Not StoreChangeHistory
				And MultipleValuesInputProhibited(ObjectContactInformationRow.Kind, Object.ContactInformation, 
					ObjectContactInformationRow.Date, StoreChangeHistory)
				Or ContactInformationRows.Count() > 0 Then
				Continue;
			EndIf;
			
			ContactInformationRow = Object.ContactInformation.Add();
			
		EndIf;
		
		FillObjectContactInformationFromString(ObjectContactInformationRow, StoreChangeHistory, 
			ContactInformationRow);
		
	EndDo;

EndProcedure

Procedure SetObjectContactInformationForRef(Ref, Val ContactInformation, MetadataObject, 
	Replace = True) Export
	
	If ContactInformation.Count() = 0 And Not Replace Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add(MetadataObject.FullName());
	LockItem.SetValue("Ref", Ref);
	
	BeginTransaction();
	Try
	
		Block.Lock();
		Object = Ref.GetObject();
		Object.Lock();
		
		If ContactInformation.Count() = 0 Then
			// Clearing contact information using a blank table.
			Object.ContactInformation.Clear();
		Else
			SetObjectContactInformation(Object, ContactInformation, MetadataObject, Replace);
		EndIf;
		
		Object.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure SetObjectsContactInformationForRef(ContactInformationOwner, 
	ObjectContactInformationRows, Val Replace) Export
	
	Ref = ContactInformationOwner.Key;
	MetadataObject = Metadata.FindByType(TypeOf(Ref));
	
	Block = New DataLock;
	LockItem = Block.Add(MetadataObject.FullName());
	LockItem.SetValue("Ref", Ref);
	
	BeginTransaction();
	Try
	
		Block.Lock();
		Object = Ref.GetObject();
		Object.Lock();
		
		SetObjectsContactInformation(ContactInformationOwner, Object, 
			ObjectContactInformationRows, Replace);
		
		Object.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure SetObjectsContactInformation(ContactInformationOwner, Object, Val ObjectContactInformationRows, Val Replace) Export
	
	If Replace Then
		Object.ContactInformation.Clear();
	EndIf;
	
	For Each ObjectContactInformationRow In ObjectContactInformationRows Do // ValueTableRow of See ContactsManager.NewContactInformation
		
		StoreChangeHistory = ContactInformationOwner.Value["Periodic"] 
			And ObjectContactInformationRow.Kind.StoreChangeHistory;
		
		If Replace Then
			
			If MultipleValuesInputProhibited(ObjectContactInformationRow.Kind, Object.ContactInformation, 
				ObjectContactInformationRow.Date, StoreChangeHistory) Then
				Continue;
			EndIf;
			ContactInformationRow = Object.ContactInformation.Add();
			
		Else
			
			Filter = New Structure();
			Filter.Insert("Kind", ObjectContactInformationRow.Kind);
			
			If StoreChangeHistory Then
				Filter.Insert("ValidFrom", ObjectContactInformationRow.Date);
				FoundRows = Object.ContactInformation.FindRows(Filter);
			ElsIf ValueIsFilled(ObjectContactInformationRow.Value) Then
				Filter.Insert("Value", ObjectContactInformationRow.Value);
				FoundRows = Object.ContactInformation.FindRows(Filter);
			Else
				Filter.Insert("FieldValues", ObjectContactInformationRow.FieldValues);
				FoundRows = Object.ContactInformation.FindRows(Filter);
			EndIf;
			
			If Not StoreChangeHistory
				And MultipleValuesInputProhibited(ObjectContactInformationRow.Kind, Object.ContactInformation, 
					ObjectContactInformationRow.Date, StoreChangeHistory)
				Or FoundRows.Count() > 0 Then
				Continue;
			EndIf;
			
			ContactInformationRow = Object.ContactInformation.Add();
		EndIf;
		
		FillObjectContactInformationFromString(ObjectContactInformationRow, StoreChangeHistory, ContactInformationRow);
	EndDo;

EndProcedure

Function MultipleValuesInputProhibited(ContactInformationKind, ContactInformation, Date, Periodic, TabularSectionRowID = Undefined)
	
	ContactInformationKindProperties = Common.ObjectAttributesValues(ContactInformationKind, "AllowMultipleValueInput, StoreChangeHistory");
	
	If ContactInformationKindProperties.AllowMultipleValueInput Then
		Return False;
	EndIf;
	
	Filter = New Structure("Kind", ContactInformationKind);
	
	If TabularSectionRowID <> Undefined Then
		Filter.Insert("TabularSectionRowID", TabularSectionRowID);
	EndIf;
	
	If Periodic And ContactInformationKindProperties.StoreChangeHistory Then
		Filter.Insert("ValidFrom", Date);
	EndIf;
	
	FoundRows = ContactInformation.FindRows(Filter);
	Return FoundRows.Count() > 0;
	
EndFunction

Procedure FillContactInformationTechnicalFields(ContactInformationRow, Object, ContactInformationType) Export
	
	// Filling in additional attributes of the tabular section.
	If ContactInformationType = Enums.ContactInformationTypes.Email Then
		FillTabularSectionAttributesForEmailAddress(ContactInformationRow, Object);
		
	ElsIf ContactInformationType = Enums.ContactInformationTypes.Address Then
		FillTabularSectionAttributesForAddress(ContactInformationRow, Object);
		
	ElsIf ContactInformationType = Enums.ContactInformationTypes.Phone 
		Or ContactInformationType = Enums.ContactInformationTypes.Fax Then
		FillTabularSectionAttributesForPhone(ContactInformationRow, Object);
		
	ElsIf ContactInformationType = Enums.ContactInformationTypes.WebPage Then
		FillTabularSectionAttributesForWebPage(ContactInformationRow, Object);
	EndIf;
	
EndProcedure

Function FindContactInformationStrings(ContactInformationKind, Date, ContactInformation, Periodic)
	
	Filter = New Structure("Kind", ContactInformationKind);
	If Periodic Then
		Filter.Insert("ValidFrom", Date);
	EndIf;
	FoundRows = ContactInformation.FindRows(Filter);
	Return FoundRows;
	
EndFunction

Procedure FillObjectContactInformationFromString(ObjectContactInformationRow, Periodic, ContactInformationRow)
	
	FillPropertyValues(ContactInformationRow, ObjectContactInformationRow);
	If Periodic Then
		ContactInformationRow.ValidFrom = ObjectContactInformationRow.Date;
	EndIf;
	
	If ValueIsFilled(ContactInformationRow.Value) Then
		ObjectOfContactInformation = JSONToContactInformationByFields(ContactInformationRow.Value, ObjectContactInformationRow.Type);
		FillContactInformationTechnicalFields(ContactInformationRow, ObjectOfContactInformation, ObjectContactInformationRow.Type);
	EndIf;
	
EndProcedure

// Fills the additional attributes of the "Contact information" tabular section for an address.
//
// Parameters:
//    LineOfATabularSection - LineOfATabularSection - a row of the "Contact information" tabular section to be filled.
//    Source             - XDTOObject  - contact information.
//
Procedure FillTabularSectionAttributesForAddress(LineOfATabularSection, Address)
	
	// Default values.
	LineOfATabularSection.Country = "";
	LineOfATabularSection.State = "";
	LineOfATabularSection.City  = "";
	
	If Address.Property("Country") Then
		LineOfATabularSection.Country =  Address.Country;
		
		If Metadata.DataProcessors.Find("AdvancedContactInformationInput") <> Undefined Then
			ModuleAdvancedContactInformationInput = Common.CommonModule("DataProcessors.AdvancedContactInformationInput");
			ModuleAdvancedContactInformationInput.FillInExtendedDetailsOfTablePartForAddress(Address, LineOfATabularSection);
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills the additional attributes of the "Contact information" tabular section for an email address.
//
// Parameters:
//    LineOfATabularSection - LineOfATabularSection - a row of the "Contact information" tabular section to be filled.
//    Source             - XDTODataObject  - contact information.
//
Procedure FillTabularSectionAttributesForEmailAddress(LineOfATabularSection, Source)
	
	Result = CommonClientServer.ParseStringWithEmailAddresses(LineOfATabularSection.Presentation, False);
	
	If Result.Count() > 0 Then
		LineOfATabularSection.EMAddress = Result[0].Address;
		
		Pos = StrFind(LineOfATabularSection.EMAddress, "@");
		If Pos <> 0 Then
			LineOfATabularSection.ServerDomainName = Mid(LineOfATabularSection.EMAddress, Pos+1);
		EndIf;
	EndIf;
	
EndProcedure

// Fills the additional attributes of the "Contact information" tabular section for phone and fax numbers.
//
// Parameters:
//    LineOfATabularSection - LineOfATabularSection - a row of the "Contact information" tabular section to be filled.
//    Source             - XDTOObject  - contact information.
//
Procedure FillTabularSectionAttributesForPhone(LineOfATabularSection, Phone)
	
	If Not ValueIsFilled(Phone) Then
		Return;
	EndIf;
	
	// Default values.
	LineOfATabularSection.PhoneNumberWithoutCodes = "";
	LineOfATabularSection.PhoneNumber         = "";
	
	CountryCode     = Phone.CountryCode;
	CityCode     = Phone.AreaCode;
	PhoneNumber = Phone.Number;
	
	If StrStartsWith(CountryCode, "+") Then
		CountryCode = Mid(CountryCode, 2);
	EndIf;
	
	Pos = StrFind(PhoneNumber, ",");
	If Pos <> 0 Then
		PhoneNumber = Left(PhoneNumber, Pos-1);
	EndIf;
	
	Pos = StrFind(PhoneNumber, Chars.LF);
	If Pos <> 0 Then
		PhoneNumber = Left(PhoneNumber, Pos-1);
	EndIf;
	
	LineOfATabularSection.PhoneNumberWithoutCodes = RemoveSeparatorsFromPhoneNumber(PhoneNumber);
	LineOfATabularSection.PhoneNumber         = RemoveSeparatorsFromPhoneNumber(String(CountryCode) + CityCode + PhoneNumber);
	
EndProcedure

// Fills the additional attributes of the "Contact information" tabular section for phone and fax numbers.
//
// Parameters:
//    LineOfATabularSection - LineOfATabularSection - a row of the "Contact information" tabular section to be filled.
//    Source             - Structure
//                         - XDTODataObject - contact information.
//
Procedure FillTabularSectionAttributesForWebPage(LineOfATabularSection, Source)
	
// Default values.
	LineOfATabularSection.ServerDomainName = "";
	
	If TypeOf(Source) = Type("Structure") Then
		
		If Source.Property("value") Then
			AddressAsString = Source.value;
		EndIf;
		
	Else
		
		AddressAsString = "";
		ContactsManagerLocalization.OnFillTabularSectionAttributesForWebPage(Source, AddressAsString);
		If IsBlankString(AddressAsString) Then
			Return;
		EndIf;
		
	EndIf;
	
	// Delete the protocol.
	Position = StrFind(AddressAsString, "://");
	ServerAddress = ?(Position = 0, AddressAsString, Mid(AddressAsString, Position + 3));
	
	LineOfATabularSection.ServerDomainName = ServerAddress;
	
EndProcedure

// Removes separators from a phone number.
//
// Parameters:
//    PhoneNumber - String - a phone or fax number.
//
// Returns:
//     String - a phone or fax number without separators.
//
Function RemoveSeparatorsFromPhoneNumber(Val PhoneNumber)
	
	Pos = StrFind(PhoneNumber, ",");
	If Pos <> 0 Then
		PhoneNumber = Left(PhoneNumber, Pos-1);
	EndIf;
	
	PhoneNumber = StrReplace(PhoneNumber, "-", "");
	PhoneNumber = StrReplace(PhoneNumber, " ", "");
	PhoneNumber = StrReplace(PhoneNumber, "+", "");
	
	Return PhoneNumber;
	
EndFunction

#EndRegion

#Region PrivateForCompatibility

Function ContactsFilledIn(Val  ContactInformation) Export
	
	Return HasFilledContactInformationProperties(ContactInformation);
	
EndFunction

Function HasFilledContactInformationProperties(Val Owner)
	
	If Owner = Undefined Then
		Return False;
	EndIf;
	
	If Not Owner.Property("Value") Or Not Owner.Property("Type") Then
		Return False;
	EndIf;
	
	If IsBlankString(Owner.value) Or IsBlankString(Owner.type) Then
		Return False;
	EndIf;
	
	If IsAddressType(Owner.Type) 
	   And ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		FieldsListToCheck = New Array();
		FieldsListToCheck.Add("Country");
	
		ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
		CommonClientServer.SupplementArray(FieldsListToCheck, 
			ModuleAddressManagerClientServer.AddressLevelNames(Owner, True));
		
		For Each FieldName In FieldsListToCheck Do
			If Owner.Property(FieldName) And ValueIsFilled(Owner[FieldName]) Then
				Return True;
			EndIf;
		EndDo;
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Procedure ReplaceInStructureUndefinedWithEmptyString(CrawledStructure) Export
	
	For Each KeyValue In CrawledStructure Do
		If TypeOf(KeyValue.Value) = Type("Structure")Then
			ReplaceInStructureUndefinedWithEmptyString(CrawledStructure[KeyValue.Key]);
		ElsIf KeyValue.Value = Undefined Then
			CrawledStructure[KeyValue.Key] = "";
		EndIf;
	EndDo;

EndProcedure

Function ConvertStringToFieldsList(FieldsString) Export
	
	// Conversion of XML serialization is not required.
	If ContactsManagerClientServer.IsXMLContactInformation(FieldsString) Then
		Return FieldsString;
	EndIf;
	
	Result = New ValueList;
	
	FieldsValuesStructure = FieldsValuesStructure(FieldsString);
	For Each Simple In FieldsValuesStructure Do
		Result.Add(Simple.Value, Simple.Key);
	EndDo;
	
	Return Result;
	
EndFunction

Function FieldsValuesStructure(FieldsString, ContactInformationKind = Undefined) Export
	
	If ContactInformationKind = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Result = ContactsManagerClientServer.AddressFieldsStructure();
	ElsIf ContactInformationKind = PredefinedValue("Enum.ContactInformationTypes.Phone") Then
		Result = ContactsManagerClientServer.PhoneFieldStructure();
	Else
		Result = New Structure;
	EndIf;
	
	LastItem = Undefined;
	
	For Iteration = 1 To StrLineCount(FieldsString) Do
		ReceivedString = StrGetLine(FieldsString, Iteration);
		If StrStartsWith(ReceivedString, Chars.Tab) Then
			If Result.Count() > 0 Then
				Result.Insert(LastItem, Result[LastItem] + Chars.LF + Mid(ReceivedString, 2));
			EndIf;
		Else
			CharPosition = StrFind(ReceivedString, "=");
			If CharPosition <> 0 Then
				NameOfField = Left(ReceivedString, CharPosition - 1);
				Simple = Mid(ReceivedString, CharPosition + 1);
				If NameOfField = "State" Or NameOfField = "District" Or NameOfField = "City" 
					Or NameOfField = "Locality" Or NameOfField = "Street" Then
					If StrFind(FieldsString, NameOfField + "Abbr") = 0 Then
						Result.Insert(NameOfField + "Abbr", AddressShortForm(Simple));
					EndIf;
				EndIf;
				Result.Insert(NameOfField, Simple);
				LastItem = NameOfField;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

Function AddressShortForm(Val GeographicalName)
	
	Abbr = "";
	WordArray = StrSplit(GeographicalName, " ", False);
	If WordArray.Count() > 1 Then
		Abbr = WordArray[WordArray.Count() - 1];
	EndIf;
	
	Return Abbr;
	
EndFunction

Function PhoneFaxDeserializationInJSON(FieldValues, Presentation = "", ExpectedType = Undefined)
	
	If ContactsManagerClientServer.IsXMLContactInformation(FieldValues) Then
		
		Result = Undefined;
		ContactsManagerLocalization.OnConvertContactInformationFromXML(FieldValues, Result, ExpectedType);
		If Result <> Undefined Then
			Return Result;
		EndIf;
		
	EndIf;
	
	Data = ContactsManagerClientServer.NewContactInformationDetails(ExpectedType);
	
	// Get from key—pair values.
	FieldsValueList = Undefined;
	If TypeOf(FieldValues) = Type("ValueList") Then
		FieldsValueList = FieldValues;
	ElsIf Not IsBlankString(FieldValues) Then
		FieldsValueList = ConvertStringToFieldsList(FieldValues);
	EndIf;
	
	PresentationField = "";
	If FieldsValueList <> Undefined Then
		For Each Simple In FieldsValueList Do
			Field = Upper(Simple.Presentation);
			
			If Field = "COUNTRYCODE" Then
				Data.CountryCode = Simple.Value;
				
			ElsIf Field = "CITYCODE" Then
				Data.AreaCode = Simple.Value;
				
			ElsIf Field = "PHONENUMBER" Then
				Data.Number = Simple.Value;
				
			ElsIf Field = "PHONEEXTENSION" Then
				Data.ExtNumber = Simple.Value;
				
			ElsIf Field = "PRESENTATION" Then
				PresentationField = TrimAll(Simple.Value);
				
			EndIf;
			
		EndDo;
		
		// Presentation with priorities.
		If Not IsBlankString(Presentation) Then
			Data.Value = Presentation;
		ElsIf ValueIsFilled(PresentationField) Then
			Data.Value = PresentationField;
		Else
			Data.Value = PhonePresentation(Data);
		EndIf;
		
		Return Data;
	EndIf;
	
	// Parsing from the presentation.
	
	// Digit groups separated by non-digits: country code, area code, phone number, and extension. 
	// The extension includes leading and trailing non-whitespace characters.
	Position = 1;
	Data.CountryCode  = FindDigitSubstring(Presentation, Position);
	CityBeginning = Position;
	
	Data.AreaCode  = FindDigitSubstring(Presentation, Position);
	Data.Number    = FindDigitSubstring(Presentation, Position, " -");
	
	PhoneExtension = TrimAll(Mid(Presentation, Position));
	If StrStartsWith(PhoneExtension, ",") Then
		PhoneExtension = TrimL(Mid(PhoneExtension, 2));
	EndIf;
	If Upper(Left(PhoneExtension, 3 ))= "EXT" Then
		PhoneExtension = TrimL(Mid(PhoneExtension, 4));
	EndIf;
	If Upper(Left(PhoneExtension, 1 ))= "." Then
		PhoneExtension = TrimL(Mid(PhoneExtension, 2));
	EndIf;
	Data.ExtNumber = TrimAll(PhoneExtension);
	
	// Fix possible errors.
	If IsBlankString(Data.Number) Then
		If StrStartsWith(TrimL(Presentation), "+") And StrLen(Presentation) > CityBeginning Then
			// An attempt to specify the area code explicitly is detected. Leaving the area code "as is".
			Data.AreaCode  = "";
			Data.Number      = RemoveNonDigitCharacters(Mid(Presentation, CityBeginning));
			Data.ExtNumber = "";
		Else
			Data.CountryCode  = "";
			Data.AreaCode  = "";
			Data.Number      = Presentation;
			Data.ExtNumber = "";
		EndIf;
	EndIf;
	
	Data.Value = Presentation;
	Return Data;
EndFunction

Function FindDigitSubstring(Text, StartPosition = Undefined, AllowedBesidesNumbers = "") Export
	
	If StartPosition = Undefined Then
		StartPosition = 1;
	EndIf;
	
	Result = "";
	EndPosition1 = StrLen(Text);
	BeginningSearch  = True;
	
	While StartPosition <= EndPosition1 Do
		Char = Mid(Text, StartPosition, 1);
		IsDigit = Char >= "0" And Char <= "9";
		
		If BeginningSearch Then
			If IsDigit Then
				Result = Result + Char;
				BeginningSearch = False;
			EndIf;
		Else
			If IsDigit Or StrFind(AllowedBesidesNumbers, Char) > 0 Then
				Result = Result + Char;    
			Else
				Break;
			EndIf;
		EndIf;
		
		StartPosition = StartPosition + 1;
	EndDo;
	
	// Discarding possible hanging separators on the right.
	Return RemoveNonDigitCharacters(Result, AllowedBesidesNumbers, False);
	
EndFunction

Function RemoveNonDigitCharacters(Text, AllowedBesidesNumbers = "", Direction = True) Export
	
	Length = StrLen(Text);
	If Direction Then
		// Left trim.
		IndexOf = 1;
		End  = 1 + Length;
		Step    = 1;
	Else
		// Right trim.    
		IndexOf = Length;
		End  = 0;
		Step    = -1;
	EndIf;
	
	While IndexOf <> End Do
		Char = Mid(Text, IndexOf, 1);
		IsDigit = (Char >= "0" And Char <= "9") Or StrFind(AllowedBesidesNumbers, Char) = 0;
		If IsDigit Then
			Break;
		EndIf;
		IndexOf = IndexOf + Step;
	EndDo;
	
	If Direction Then
		// Left trim.
		Return Right(Text, Length - IndexOf + 1);
	EndIf;
	
	// Right trim.
	Return Left(Text, IndexOf);
	
EndFunction

#EndRegion

Function ContactInformationToJSONStructure(ContactInformation, Val Type = Undefined, SettingsOfConversion = Undefined) Export
	
	If SettingsOfConversion = Undefined Then
		SettingsOfConversion = ContactsManager.ContactInformationConversionSettings();
	EndIf;
	
	If Type <> Undefined And TypeOf(Type) <> Type("EnumRef.ContactInformationTypes") Then
		Type = ContactsManagerInternalCached.ContactInformationKindType(Type);
	EndIf;
	
	If Type = Undefined Then
		If TypeOf(ContactInformation) <> Type("String") 
			Or (TypeOf(ContactInformation) = Type("String") 
				And ContactsManagerClientServer.IsXMLContactInformation(ContactInformation)) Then
				
				Type = Undefined;
				ContactsManagerLocalization.OnDefineContactInformationType(ContactInformation, Type);
		EndIf;
	EndIf;
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() 
		And Type = Enums.ContactInformationTypes.Address Then
		
		ModuleAddressManager = Common.CommonModule("AddressManager");
		Return ModuleAddressManager.ContactInformationToJSONStructure(ContactInformation, Type, SettingsOfConversion);
	EndIf;
	
	Result = ContactsManagerClientServer.NewContactInformationDetails(Type);
	
	If TypeOf(ContactInformation) = Type("Structure") Then
		
		FieldsMap = New Map();
		FieldsMap.Insert("Presentation", "value");
		FieldsMap.Insert("Comment",   "comment");
		
		If Type = Enums.ContactInformationTypes.Phone Then
			
			FieldsMap.Insert("CountryCode",     "countryCode");
			FieldsMap.Insert("CityCode",     "areaCode");
			FieldsMap.Insert("PhoneNumber", "number");
			FieldsMap.Insert("PhoneExtension",    "extNumber");
			
		EndIf;
		
		For Each ContactInformationField1 In ContactInformation Do
			FieldName = FieldsMap.Get(ContactInformationField1.Key);
			If FieldName <> Undefined Then
				Result[FieldName] = ContactInformationField1.Value;
			EndIf;
		EndDo;
		
		Return Result;
		
	EndIf;
	
	If TypeOf(ContactInformation) = Type("String") 
		And ContactsManagerClientServer.IsJSONContactInformation(ContactInformation) Then
			Return JSONToContactInformationByFields(ContactInformation, Type);
	EndIf;
	
	ContactInformationInJSON = Undefined;
	ContactsManagerLocalization.OnConvertContactInformationToJSONStructure(ContactInformation, 
		ContactInformationInJSON, Type, SettingsOfConversion);
	
	If ContactInformationInJSON <> Undefined Then
		Return ContactInformationInJSON;
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Value - Structure
// 
// Returns:
//  String
//
Function ToJSONStringStructure(Value) Export
	
	ContactInformationByFields = New Structure;
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	
	For Each StructureItem In Value Do
		If IsBlankString(StructureItem.Value) And StructureItem.Value <> "" Then
			// Converting undefined, NULL, and insignificant characters to an empty string.
			Value[StructureItem.Key] = "";
		ElsIf TypeOf(StructureItem.Value) = Type("Array") Then
			
			IndexOf = StructureItem.Value.Count() - 1;
			While IndexOf >=0 Do
				
				If StrCompare(StructureItem.Key, "apartments") = 0 
					Or StrCompare(StructureItem.Key, "buildings") = 0 Then
						ValueToCheck = StructureItem.Value[IndexOf].number;
				ElsIf StrCompare(StructureItem.Key, "admLevels") = 0 
					Or StrCompare(StructureItem.Key, "munLevels") = 0 Then
						ValueToCheck = StructureItem.Value[IndexOf];
				Else
					IndexOf = IndexOf - 1;
					Continue;
				EndIf;
				
				If IsBlankString(ValueToCheck) Then
					StructureItem.Value.Delete(IndexOf);
				EndIf;
				
				IndexOf = IndexOf - 1;
			EndDo;
			
		EndIf;
		If ValueIsFilled(StructureItem.Value) Then
			ContactInformationByFields.Insert(StructureItem.Key, StructureItem.Value);
		EndIf;
	EndDo;
	
	If ContactInformationByFields.Property("area") And ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ModuleAddressManager.KemerovoRegionTypeInstallation(ContactInformationByFields);
		
	EndIf;
	
	WriteJSON(JSONWriter, ContactInformationByFields,, "ContactInformationFieldsAdjustment", 
		ContactsManagerInternal);
	
	Return JSONWriter.Close();
	
EndFunction

Function ContactInformationFieldsAdjustment(Property, Value, ConversionFunctionAdditionalParameters, Cancel) Export
	
	If TypeOf(Value) = Type("UUID") Then
		Return String(Value);
	EndIf;
	
EndFunction

// Parameters:
//  Value - String 
//  ContactInformationType - CatalogRef.ContactInformationKinds
//                          - Structure 
//                          - EnumRef.ContactInformationTypes
//
// Returns:
//   See AddressManagerClientServer.NewContactInformationDetails
//
Function JSONToContactInformationByFields(Val Value, ContactInformationType) Export
	
	Value = StrReplace(Value, "\R\N", "\r\n"); // Fix newline characters.
	
	Result = New Structure();
	
	ContactInformation = JSONStringToStructure1(Value);
	
	If Not ValueIsFilled(ContactInformationType) Then
		If ContactInformation.Property("type") Then
			ContactInformationType = ContactInformationTypeFromRow(ContactInformation.type);
		EndIf;
	EndIf;
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
		Result = ModuleAddressManagerClientServer.NewContactInformationDetails(ContactInformationType);
	Else
		Result = ContactsManagerClientServer.NewContactInformationDetails(ContactInformationType);
	EndIf;
	
	If ContactInformation.Property("area") And ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ModuleAddressManager.KemerovoRegionTypeInstallation(ContactInformation);
		
	EndIf;
		
	FillPropertyValues(Result, ContactInformation);
	
	Return Result;
	
EndFunction

Function ContactInformationTypeFromRow(Val ContactInformationTypeAsString) Export
	
	Result = New Map;
	Result.Insert("Address", PredefinedValue("Enum.ContactInformationTypes.Address"));
	Result.Insert("Phone", PredefinedValue("Enum.ContactInformationTypes.Phone"));
	Result.Insert("Email", PredefinedValue("Enum.ContactInformationTypes.Email"));
	Result.Insert("Skype", PredefinedValue("Enum.ContactInformationTypes.Skype"));
	Result.Insert("WebPage", PredefinedValue("Enum.ContactInformationTypes.WebPage"));
	Result.Insert("Fax", PredefinedValue("Enum.ContactInformationTypes.Fax"));
	Result.Insert("Other", PredefinedValue("Enum.ContactInformationTypes.Other"));
	
	Return Result[ContactInformationTypeAsString];
	
EndFunction

Function JSONStringToStructure1(Value) Export
	
	JSONReader = New JSONReader;
	JSONReader.SetString(Value);
	
	Try
		Result = ReadJSON(JSONReader,,,, "RestoreContactInformationFields", 
			ContactsManagerInternal);
	Except
		ErrorText = NStr("vi = 'Sai hằng thông tin.';
						|ru = 'Некорректная контактная информация.';
						|en = 'Invalid contact information.'; fa = 'Invalid contact information.';
						|it = 'Invalid contact information.';
						|pl = 'Invalid contact information.';
						|tr = 'İrtibat bilgileri yanlış.'");
		WriteLogEvent(EventLogEvent(),
			EventLogLevel.Error,,,
			ErrorText + Chars.LF + String(Value));
		Result = New Structure;
		
	EndTry;
	
	JSONReader.Close();
	Return Result;
	
EndFunction

Function RestoreContactInformationFields(Property, Value, ConversionFunctionAdditionalParameters) Export
	
	If StrEndsWith(Upper(Property), "ID") And StrLen(Value) = 36 Then
		Return New UUID(Value);
	EndIf;
	
	If StrCompare(Property, "houseType") = 0 Then
		Return Title(Value);
	EndIf;
	
	If (StrCompare(Property, "buildings") = 0
		Or StrCompare(Property, "apartments") = 0)
		And TypeOf(Value) = Type("Array") Then
		For Each ArrayValue In Value Do
			ArrayValue.type = Title(ArrayValue.type);
		EndDo;
		
		Return Value;
	EndIf;
	
EndFunction

Function PhoneNumberMatchesMask(PhoneNumber, Mask) Export 
	
	CharsCount = StrLen(PhoneNumber);
	
	If CharsCount <> StrLen(Mask) Then
		Return False;
	EndIf;
	
	MaskCharsToCheck = MaskCharsToCheck();
	
	For CharacterNumber = 1 To CharsCount Do
		MaskChar = Mid(Mask, CharacterNumber, 1);
		PhoneNumberChar = Mid(PhoneNumber, CharacterNumber, 1);
		If MaskChar = "9"  Then
			If Not StringFunctionsClientServer.OnlyNumbersInString(PhoneNumberChar,,False) Then 
				Return False;  
			Else
				Continue;
			EndIf;		
		EndIf;
			
		If MaskCharsToCheck.Get(MaskChar) = Undefined And MaskChar <> PhoneNumberChar Then
			Return False;	
		EndIf;		
	EndDo; 
	
	Return True;
	
EndFunction

Function MaskCharsToCheck()
	
	MaskChars = New Map;
	
	MaskChars.Insert( "!", True);
	MaskChars.Insert( "#", True);
	MaskChars.Insert( "N", True);
	MaskChars.Insert( "U", True);
	MaskChars.Insert( "X", True);
	MaskChars.Insert( "h", True);
	MaskChars.Insert( "@", True);
	
	Return MaskChars;
	
EndFunction

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("SessionParametersSetting");
	Methods.Insert("SetUsageFlagValue");
	Methods.Insert("UpdatePhoneExtensionSettings");
	Methods.Insert("UpdateExistingWorldCountries");
	Methods.Insert("CheckContactInformationKinds");
	Methods.Insert("CorrectContactInformationKindsInBackground", True);
	
EndProcedure

#EndRegion