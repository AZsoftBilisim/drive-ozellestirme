#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If Not ValueIsFilled(CompanyIndividual) Then
		If ValueIsFilled(FillingData)
		 And FillingData.Property("CompanyType")
		 And FillingData.CompanyType = "IndividualEntrepreneur" Then
			CompanyIndividual = Enums.CompanyIndividual.Individual;
		Else
			CompanyIndividual = Enums.CompanyIndividual.BusinessEntity;
		EndIf;
	EndIf;
	If IsNew() Then
		Status = Enums.BusinessUnitCompanyStatuses.Valid;
	EndIf;
	If ValueIsFilled(FillingData) And FillingData.Property("CompanyType") Then
		If FillingData.CompanyType = "BusinessEntity" Then
			LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Entity");
			BranchOffice = False;
		ElsIf FillingData.CompanyType = "IndividualEntrepreneur" Then 
			LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.IndividualEntrepreneur");
			BranchOffice = False;
			TIN = Common.ObjectAttributeValue(IndividualEntrepreneur, "TIN");
		ElsIf FillingData.CompanyType = "BranchOffice" Then
			LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Entity");
			BranchOffice = True;
			TIN = Common.ObjectAttributeValue(ParentCompany, "TIN");
		Else Raise NStr("vi = 'Không thể tạo doanh nghiệp. Trên biểu mẫu đã chuyển đến những tham số không chính xác.
											|Hãy liên hệ với người quản trị.';
											|ru = 'Создание организации невозможно. На форму переданы неверные параметры.
											|Обратитесь к администратору.';
											|en = 'Cannot create company. Invalid parameters were passed to the form.
											|Please contact the administrator.'; fa = 'Cannot create company. Invalid parameters were passed to the form.
											|Please contact the administrator.';
											|it = 'Impossibile creare le aziende. Parametri errati inviati al modulo.
											|Contattare l''amministratore.';
											|pl = 'Utworzenie firmy jest niemożliwe. Do formularzu przekazano nieprawidłowe parametry.
											|Zwróć się do administratora.';
											|tr = 'İş yeri oluşturma mümkün değildir. Forma geçersiz parametreler aktarıldı.
											|Yöneticiyle iletişime geçin.'");
		EndIf;
	EndIf;
	
	If ValueIsFilled(FillingData) And FillingData.Property("Status") Then
		Status = FillingData.Status;
	EndIf;
	
	If IsNew() And Not GetFunctionalOption("UseMultipleCurrencies") Then
		LocalAccountingCurrency = Catalogs.Currencies.GetDefaultCurrency();
		If Not ValueIsFilled(LocalAccountingCurrency) Then
			Raise NStr("vi = 'Không thể điền trường ""Tiền tệ kế toán tài chính"". Có thể là trong cơ sở thông tin chưa nhập tiền tệ nào
			|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị"" - ""Tập đoàn"" - ""Tiền tệ"".';
			|ru = 'Не удалось заполнить поле ""Валюта регламентированного учета"". Возможно, в информационной базе не введено ни одной валюты
			|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Валюты"".';
			|en = 'Cannot fill in the ""Local accounting currency"" field. Probably no currencies are registered in the infobase.
			|To create currencies, go to ""Master data and settings"" – ""Enterprise"" – ""Currencies"".'; fa = 'Cannot fill in the ""Local accounting currency"" field. Probably no currencies are registered in the infobase.
			|To create currencies, go to ""Master data and settings"" – ""Enterprise"" – ""Currencies"".';
			|it = 'Impossibile compilare il campo ""Valuta della contabilità regolatoria"". È possibile che nell''infobase non sia inserita alcuna valuta
			|Per l''impostazione è necessario passare alla sezione ""Informazioni di riferimento e amministrazione""-""Impresa""-""Valute"".';
			|pl = 'Nie udało się wypełnić pola ""Waluta ewidencji reglamentowanej"". Możliwe, że w bazie informacyjnej nie wprowadzono żadnej waluty
			|Do ustawienia należy przejść do rozdziału ""Ustawienia""-""Przedsiębiorstwo""-""Waluty"".';
			|tr = '""Düzenlenmiş Muhasebe Para Birimi"" alanı doldurulamadı. Infobase''te herhangi bir para birimi girilmemiş olabilir
			|Ayarlamak için ""Master veri ve Yönetim""-""İş yeri""-""Para Birimleri"" bölümüne git.'");
		EndIf;
	EndIf;
	
	If IsNew() And Not GetFunctionalOption("UseMultiCountryAccounting") Then
		RegistrationCountry = SettingsValueClientServerCached.MainCountry();
	EndIf;
	
	CompaniesLocalization.ProcessingOrganizationFields(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	Var MessageText;
	
	NotCheckedAttributeArray = New Array;

	If BranchOffice Then
		CheckedElement = CheckedAttributes.Find("LocalAccountingCurrency");
		If CheckedElement <> Undefined Then
			CheckedAttributes.Delete(CheckedElement);
		EndIf;
	Else
		NotCheckedAttributeArray.Add("ParentCompany");
	EndIf;
	
	If Not CompanyIsMajorTaxpayer Then
		NotCheckedAttributeArray.Add("IFTSCodeOfReportingRecipient");
	EndIf;
	
	If Not IsNew()
		And BranchOffice
		And ThereAreSeparateDivisionsOfOrganization() Then
		
		MessageText = NStr("vi = 'Doanh nghiệp không thể là bộ phận độc lập, bởi vì đã chọn doanh nghiệp này làm doanh nghiệp mẹ cho các doanh nghiệp khác.';
							|ru = 'Организация не может быть обособленным подразделением, потому что она уже выбрана в качестве головной для других организаций.';
							|en = 'Company cannot be a branch office as it has already been selected as the parent company for other companies.'; fa = 'Company cannot be a branch office as it has already been selected as the parent company for other companies.';
							|it = 'L''organizzazione non può essere una divisione separata, poiché è già selezionata come reparto principale per altre organizzazioni.';
							|pl = 'Firma nie może być odrębnym działem, ponieważ jest ona już wybrana jako główna dla innych firmy.';
							|tr = 'İş yeri, diğer iş yerleri için üst iş yeri olarak zaten seçilmiş olduğundan, ayrı departman olamaz.'");
		
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
	EndIf;
	
	If IsNew() And Not GetFunctionalOption("UseMultiCountryAccounting") Then
		NotCheckedAttributeArray.Add("RegistrationCountry");
		Constants.MainCountry.CheckFilling();
	EndIf;
	If Not IsNew() Then
		ActiveParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("TaxationSystemSettings", Ref,,False);
		If ValueIsFilled(ActiveParameters) Then
			If LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur
				And ActiveParameters.TaxationSystem =  Enums.TaxationSystems.Shared3 Then
				
				MessageText = NStr("vi = 'Đối với cá nhân kinh doanh, chỉ có thể sử dụng hệ thống thuế giản lược.';
									|ru = 'Для индивидуального предпринимателя доступна только упрощенная система налогообложения.';
									|en = 'For an individual entrepreneur simplified taxation system is available only.'; fa = 'For an individual entrepreneur simplified taxation system is available only.';
									|it = 'Per l''imprenditore individuale è disponibile solo il regime fiscale semplificato.';
									|pl = 'Dla przedsiębiorcy indywidualnego jest dostępny tylko uproszczony system opodatkowania.';
									|tr = 'Şahıs şirketi için yalnızca basitleştirilmiş vergilendirme sistemi mevcuttur.'");
				Common.MessageToUser(MessageText, ThisObject,,, Cancel);
				
			EndIf;
		EndIf;
	EndIf;
	If Ref = Catalogs.Companies.ManagementCompany Then
		NotCheckedAttributeArray.Add("Status");
	EndIf;
	
	CompaniesLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

Procedure BeforeWrite(Cancel)
	
	If GetFunctionalOption("BaseVersion") And IsNew() Then
		DefaultCompany = Catalogs.Companies.DefaultCompany();
		If ValueIsFilled(DefaultCompany) Then
			Common.MessageToUser(NStr("vi = 'Trong phiên bản căn bản, chỉ có thể tiến hành kế toán theo một doanh nghiệp';
										|ru = 'Базовая версия может вести учет только по одной организации';
										|en = 'Base version can keep records only for one company'; fa = 'Base version can keep records only for one company';
										|it = 'La versione base può conservare i record di una sola organizzazione';
										|pl = 'Podstawowa wersja może prowadzić ewidencję tylko wg jednej firmy';
										|tr = 'Temel sürüm, yalnızca bir iş yeri için kayıt tutabilir'"),,,, Cancel);	
		EndIf;
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If PartnersAndCounterparties.ThisIsYurFace(LegalEntityIndividual) = False Then

		CompanyIndividual = Enums.CompanyIndividual.Individual;
		CRTR = "";
		
	Else
		
		CompanyIndividual = Enums.CompanyIndividual.BusinessEntity;
		SertificateDateOfIssue   = Date(1,1,1);
		SeriesAndNumber   = "";
		
	EndIf;
	
	If BranchOffice Then
		If Not ValueIsFilled(LocalAccountingCurrency) Then
			LocalAccountingCurrency = Common.ObjectAttributeValue(ParentCompany,
																			"LocalAccountingCurrency")
		EndIf;
	
	Else
		
		If IsNew() Then
			If GetNewObjectRef().IsEmpty() Then
				SetNewObjectRef(Catalogs.Companies.GetRef());
			EndIf;
			ParentCompany = GetNewObjectRef();
		ElsIf ParentCompany <> Ref Then
			ParentCompany = Ref;
		EndIf;
		
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		SetPrivilegedMode(True);
		Query = New Query(
		"SELECT TOP 1
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref <> &Ref
		|	AND Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
		|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)");
		
		Query.SetParameter("Ref", Ref);
		If Not Query.Execute().IsEmpty() Then
			If Not GetFunctionalOption("BaseVersion") Then
				Constants.UseMultipleCompanies.Set(True);
				Constants.UseMultipleCashAccounts.Set(True);
				Constants.UseMultipleBankAccounts.Set(True);
				Constants.UseSeveralBankAccountsOrCashAccounts.Set(True);
			Else
				Common.MessageToUser(NStr("vi = 'Trong phiên bản căn bản, chỉ có thể tiến hành kế toán theo một doanh nghiệp';
											|ru = 'Базовая версия может вести учет только по одной организации';
											|en = 'Base version can keep records only for one company'; fa = 'Base version can keep records only for one company';
											|it = 'La versione base può conservare i record di una sola organizzazione';
											|pl = 'Podstawowa wersja może prowadzić ewidencję tylko wg jednej firmy';
											|tr = 'Temel sürüm, yalnızca bir iş yeri için kayıt tutabilir'"),,,, Cancel);
			EndIf;
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	
	If Status = Enums.BusinessUnitCompanyStatuses.NotValid Then
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.Text = 
		"SELECT
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
		|	AND NOT Companies.DeletionMark
		|	AND Companies.ParentCompany = &Ref
		|	AND Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
		|	AND Companies.Ref <> &Ref";
		If Not Query.Execute().IsEmpty() Then
			Common.MessageToUser(NStr("vi = 'Không thể thiết lập trạng thái ""Không có hiệu lực"" cho doanh nghiệp mẹ có các bộ phận độc lập đang còn hiệu lực';
										|ru = 'Статус ""Не действует"" не может быть установлен для головной организации с действущими обособленными подразделениями';
										|en = 'Cannot set the ""Inactive"" status for a parent company with operating branch offices'; fa = 'Cannot set the ""Inactive"" status for a parent company with operating branch offices';
										|it = 'Статус ""Не действует"" не может быть установлен для головной организации с действущими обособленными подразделениями';
										|pl = 'Cannot set the ""Inactive"" status for a parent company with operating branch offices';
										|tr = 'Aktif ayrı departmanları olan ana iş yeri için ""Geçerli değil"" durumu ayarlanamaz'"),,,, Cancel);
		EndIf;
		If ParentCompany <> Ref 
			And Common.ObjectAttributeValue(ParentCompany, "Status") = Enums.BusinessUnitCompanyStatuses.NotValid 
			And Status = Enums.BusinessUnitCompanyStatuses.Valid Then
			Common.MessageToUser(NStr("vi = 'Đã chọn doanh nghiệp mẹ có trạng thái ""Không có hiệu lực"". Cần chọn doanh nghiệp mẹ đang còn hiệu lực';
										|ru = 'Выбрана головная организация со статусом ""Не действует"". Должна быть выбрана действующая головная организация';
										|en = 'A parent company with the ""Inactive"" status is selected. Select an operating parent company'; fa = 'A parent company with the ""Inactive"" status is selected. Select an operating parent company';
										|it = 'Выбрана головная организация со статусом ""Не действует"". Должна быть выбрана действующая головная организация';
										|pl = 'A parent company with the ""Inactive"" status is selected. Select an operating parent company';
										|tr = 'Durumu ""Geçerli değil"" olan ana iş yeri seçildi. Geçerli ana iş yeri seçilmelidir'"),,,, Cancel);
		EndIf;
	EndIf;
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
	CompaniesLocalization.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RefreshReusableValues();
	TMCommonUse.SyncKeys(ThisObject);
	
	If ValueIsFilled(LocalAccountingCurrency) Then
		ProcessingOfExchangeRatesTM.CheckCorrectnessOfRelativeRateOn01_01_1980(LocalAccountingCurrency);
	EndIf;
	
	CompaniesLocalization.WhenRecordingOrganization(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	Logo            = Undefined;
	FacsimileStamp = Undefined;
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Function ThereAreSeparateDivisionsOfOrganization()
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	Companies.Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.ParentCompany = &Ref
	|	AND Companies.Ref <> Companies.ParentCompany
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|";
	
	Query.SetParameter("Ref", Ref);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	Result.Insert("Catalog.DimensionKeysOfAccountingByPartners", "DeletionMark");
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	Result.Insert("Catalog.DocumentRegistryKeys", "DeletionMark,Description,TIN");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
