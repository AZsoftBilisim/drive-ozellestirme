
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ManagingElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" Then
		// The program settings in the administration panels have been changed
		ManagingElements();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region GeneralCatalogues

&AtClient
Procedure OpenPriceTypes(Command)
	
	OpenForm("Catalog.TypesOfPrices.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTypesOfLoyaltyCards(Command)
	
	OpenForm("Catalog.LoyaltyCardKinds.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenPriceTypesPriceList(Command)
	
	ShowValue(,PriceTypePriceList_());
	
EndProcedure

&AtClient
Procedure OpenStoreFormats(Command)
	
	OpenForm("InformationRegister.HistoryOfStoreFormatChange.Form.EditForm",, ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheProductCategory(Command)
	
	OpenForm("Catalog.ProductCategories.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenStamps(Command)
	
	OpenForm("Catalog.Brands.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenProductRangeQuotas(Command)
	
	OpenForm("Document.SetProductRangeQuotas.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenCollections(Command)
	
	OpenForm("Catalog.ItemsCollections.ListForm",, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenBonusLoyaltyPrograms(Command)
	
	OpenForm("Catalog.LoyaltyPrograms.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheTermsOfDiscountsMarkups(Command)
	
	OpenForm("Catalog.DiscountMarkupTerms.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#Region MailoutsAndNotificationsToCustomers

&AtClient
Procedure OpenMessageTemplates(Command)
	
	OpenForm("Catalog.MessageTemplates.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheGroupsNewslettersAndAlerts(Command)
	
	OpenForm("Catalog.GroupsOfMailoutsAndNotifications.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheKindsOfAlerts(Command)
	
	OpenForm("Catalog.CustomerNotificationKinds.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#Region Surveys

&AtClient
Procedure OpenQuestionsForTheSurvey(Command)
	
	OpenForm("ChartOfCharacteristicTypes.QuestionsForSurvey.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure OpenQuestionnaireTemplates(Command)
	
	OpenForm("Catalog.QuestionnaireTemplates.ListForm", , ThisObject);
	
EndProcedure

#EndRegion

#Region SalesOpportunities

&AtClient
Procedure OpenProcessStateCatalog(Command)
	
	OpenForm("Catalog.ProcessesStates.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheTypesOfTransactionsDirectory(Command)
	
	OpenForm("Catalog.CustomerOpportunityKinds.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheListOfReasonsForLosingTrades(Command)
	
	OpenForm("Catalog.ReasonsForLosingSalesOpportunities.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheDirectoryOfThePrimaryCausesOfUnmetDemand(Command)
	
	OpenForm("Catalog.ReasonsForPrimaryDemandNonFulfillment.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenThePartnerRolesInTransactionsAndProjectsDirectory(Command)
	
	OpenForm("Catalog.PartnerRolesInSalesOpportunitiesAndProjects.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheDirectoryOfContactPersonRolesInTransactionsAndProjects(Command)
	
	OpenForm("Catalog.RolesOfContactPersonsInSalesOpportunitiesAndProjects.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#Region PartnersContactPersons

&AtClient
Procedure OpenTheBusinessRegionsDirectory(Command)
	
	OpenForm("Catalog.BusinessRegions.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheDirectoryTheRoleOfContactPersons(Command)
	
	OpenForm("Catalog.RolesOfPartnerContactPersons.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenContactInformationKinds(Command)
	
	OpenForm("Catalog.ContactInformationKinds.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheTypesOfPartnerRelationshipsDirectory(Command)
	
	OpenForm("Catalog.PartnerRelationshipTypes.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenThePartnerAccessGroupDirectory(Command)
	
	OpenForm("Catalog.PartnerAccessGroups.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#Region Complaints

&AtClient
Procedure OpenTheCausesOfClaimsDirectory(Command)
	
	OpenForm("Catalog.ComplaintReasons.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()

	RecordCustomerClaims      = GetFunctionalOption("RecordComplaints");
	UseSeveralPriceTypes     = GetFunctionalOption("UseSeveralPriceTypes");
	UseDiscountsMarkupsInSales = GetFunctionalOption("UseDiscountsMarkupsInSales");
	UsePriceGroups 				  = GetFunctionalOption("UsePriceGroups");
	UseLoyaltyCards               = GetFunctionalOption("UseLoyaltyCards");
	UseLoyaltyPrograms   = GetFunctionalOption("UseLoyaltyPrograms");
	
	UsePatnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	UseTransactions_                  = GetFunctionalOption("UseSalesOpportunitiesToCustomer");
	UseOpportunityManagement      = GetFunctionalOption("UseOpportunityManagement");
	
	UsePartnerAccessGroups     = GetFunctionalOption("UsePartnerAccessGroups");
	UseRolesOfPartnerContactPersons = GetFunctionalOption("UseRolesOfPartnerContactPersons");
	UseBusinessRegions              = GetFunctionalOption("UseBusinessRegions");
	UsePartnerConnectionKinds        = GetFunctionalOption("UsePartnerConnectionKinds");
	UsePartnersAsCounterparties   = GetFunctionalOption("UsePartnersAsCounterparties");
	
	UseEmailClient 	 = GetFunctionalOption("UseEmailClient");
	UseSurvey  	 = GetFunctionalOption("UseSurvey");
	UseMessageTemplates = GetFunctionalOption("UseMessageTemplates");
	
	RightOfAccessTypesOfPrices                     = AccessRight("View", Metadata.Catalogs.TypesOfPrices);
	RightOfAccessPriceGroups 				= AccessRight("View", Metadata.Catalogs.PriceGroups);
	RightOfAccessTypesOfLoyaltyCards          = AccessRight("View", Metadata.Catalogs.LoyaltyCardKinds);
	RightOfAccessTermsOfService       = AccessRight("View", Metadata.Catalogs.DiscountMarkupTerms);
	RightOfAccessBonusLoyaltyPrograms = AccessRight("View", Metadata.Catalogs.LoyaltyPrograms);
	RightOfAccessAssortment                     = AccessRight("View", Metadata.Catalogs.ProductCategories);

	RightOfAccessClassification               = AccessRight("Use", Metadata.DataProcessors.Classification);
	
	AccessRightsForMailingAndNotificationGroups = AccessRight("View", Metadata.Catalogs.GroupsOfMailoutsAndNotifications);
	AccessRightsNotificationKinds            = AccessRight("View", Metadata.Catalogs.CustomerNotificationKinds);
	AccessRightMessageTemplates          = AccessRight("View", Metadata.Catalogs.MessageTemplates);
	
	RightOfAccessQuestionsForQuestionnaire = AccessRight("View", Metadata.ChartsOfCharacteristicTypes.QuestionsForSurvey);
	AccessRightProfileTemplates            = AccessRight("View", Metadata.Catalogs.QuestionnaireTemplates);
	
	RightOfAccessTypesOfTransactionsWithClients   = AccessRight("View", Metadata.Catalogs.CustomerOpportunityKinds);
	RightOfAccessReasonsForLosingTrades = AccessRight("View", Metadata.Catalogs.ReasonsForLosingSalesOpportunities);
	ProcessStateAccessRights     = AccessRight("View", Metadata.Catalogs.ProcessesStates);
	
	RightOfAccessPartnersRolesInTransactionsAndProjects = AccessRight(
		"View",
		Metadata.Catalogs.PartnerRolesInSalesOpportunitiesAndProjects);
		
	RightOfAccessRolesOfContactPersonsInTransactionsAndProjects = AccessRight(
		"View",
		Metadata.Catalogs.RolesOfContactPersonsInSalesOpportunitiesAndProjects);
		
	RightOfAccessReasonsForDissatisfactionWithPrimaryDemand = AccessRight(
		"View",
		Metadata.Catalogs.ReasonsForPrimaryDemandNonFulfillment);
	
	RightOfAccessReasonsForClaims = AccessRight(
		"View",
		Metadata.Catalogs.ComplaintReasons);
		
	AccessRightPartnerAccessGroups      = AccessRight("View", Metadata.Catalogs.PartnerAccessGroups);
	RightOfAccessRolesOfPartnersContactPersons  = AccessRight("View", Metadata.Catalogs.RolesOfPartnerContactPersons);
	RightOfAccessBusinessRegions               = AccessRight("View", Metadata.Catalogs.BusinessRegions);
	RightOfAccessTypesOfRelationsBetweenPartners   = AccessRight("View", Metadata.Catalogs.PartnerRelationshipTypes);
	
	RightOfAccessTypesOfContactInformation = AccessRight("View", Metadata.Catalogs.ContactInformationKinds);
	
	Items.GroupOfPriceTypesSettings.Visible            		 = RightOfAccessTypesOfPrices;
	Items.OpenPriceGroups.Visible 					 = RightOfAccessPriceGroups And UsePriceGroups;
	Items.GroupOfSettingsForLoyaltyCardTypes.Visible 		 = RightOfAccessTypesOfLoyaltyCards And UseLoyaltyCards;
	Items.GroupTermsOfDiscountsMarkups.Visible  = RightOfAccessTermsOfService And UseDiscountsMarkupsInSales;
	Items.GroupOfSettingsForBonusLoyaltyPrograms.Visible  = RightOfAccessBonusLoyaltyPrograms And UseLoyaltyPrograms;
	
	Items.GroupOfPriceTypesSettings.Visible   = RightOfAccessTypesOfPrices And UseSeveralPriceTypes;
	Items.GroupOfSettingsOneTypeOfPrice.Visible = RightOfAccessTypesOfPrices And Not UseSeveralPriceTypes;
	
	// Nomenclature sold jointly
	UseItemsSoldTogether            = GetFunctionalOption("UseItemsSoldTogether");
	RightOfAccessProductsSoldJointly            = AccessRight("View", Metadata.InformationRegisters.ProductsSoldTogether);
	RightOfAccessProductsSoldJointlyUpdate   = AccessRight("Update", Metadata.InformationRegisters.ProductsSoldTogether);
	Items.ToOpenTheSetAssociations.Visible = UseItemsSoldTogether
		And RightOfAccessProductsSoldJointlyUpdate;
	Items.OpenTheItemsSoldTogether.Visible = UseItemsSoldTogether
		And RightOfAccessProductsSoldJointly;
	
	#Region ProductRange
	
	Items.OpenStoreFormats.Visible  = AccessRight("View", Metadata.InformationRegisters.HistoryOfStoreFormatChange);
	Items.ToOpenTheProductCategory.Visible = AccessRight("View", Metadata.Catalogs.ProductCategories);
	Items.OpenStamps.Visible             = AccessRight("View", Metadata.Catalogs.Brands);
	Items.OpenProductRangeQuotas.Visible = AccessRight("View", Metadata.Documents.SetProductRangeQuotas);
	Items.OpenCollections.Visible         = AccessRight("View", Metadata.Catalogs.ItemsCollections);
	
	Items.TheGroupClassificationOfTheNomenclature.Visible = RightOfAccessClassification;
	
	#EndRegion
	
	#Region MailoutsAndNotificationsToCustomers
	
	Items.ToOpenTheGroupsNewslettersAndAlerts.Visible  = AccessRightsForMailingAndNotificationGroups And UseEmailClient And UseMessageTemplates;
	Items.ToOpenTheKindsOfAlerts.Visible             = AccessRightsNotificationKinds And UseEmailClient And UseMessageTemplates;
	Items.OpenTheMessageTemplatesDirectory.Visible = AccessRightMessageTemplates And UseMessageTemplates;
	
	#EndRegion
	
	#Region Surveys
	
	Items.OpenQuestionsForTheSurvey.Visible = RightOfAccessQuestionsForQuestionnaire And UseSurvey;
	Items.OpenQuestionnaireTemplates.Visible            = AccessRightProfileTemplates And UseSurvey;
	
	#EndRegion
	
	#Region SalesOpportunities
	
	Items.OpenTheTypesOfTransactionsDirectory.Visible = RightOfAccessTypesOfTransactionsWithClients;
	Items.OpenProcessStateCatalog.Visible = ProcessStateAccessRights;
	Items.OpenTheListOfReasonsForLosingTrades.Visible = RightOfAccessReasonsForLosingTrades;
	Items.OpenTheDirectoryOfThePrimaryCausesOfUnmetDemand.Visible = RightOfAccessReasonsForDissatisfactionWithPrimaryDemand;
	Items.OpenThePartnerRolesInTransactionsAndProjectsDirectory.Visible 	= RightOfAccessPartnersRolesInTransactionsAndProjects;
	Items.OpenTheDirectoryOfContactPersonRolesInTransactionsAndProjects.Visible = RightOfAccessRolesOfContactPersonsInTransactionsAndProjects;

	If Not UseTransactions_ Then
		
		Items.GroupOfTransactionSettings.Title = NStr("vi = 'Dự án';
														|ru = 'Проекты';
														|en = 'Projects'; fa = 'پروژه‌ها';
														|it = 'Progetti';
														|pl = 'Projects';
														|tr = 'Projeler'");
		
	EndIf;
	
	If UsePatnersAsCounterparties Then
		TeamPartnerRolesInTransactionsAndProjects = Commands.Find("OpenThePartnerRolesInTransactionsAndProjectsDirectory");
		If TeamPartnerRolesInTransactionsAndProjects <> Undefined Then
			TeamPartnerRolesInTransactionsAndProjects.Title = NStr("vi = 'Vai trò của đối tác trong vụ việc và dự án';
																	|ru = 'Роли контрагентов в сделках и проектах';
																	|en = 'Counterparty roles in sales opportunities and projects'; fa = 'Counterparty roles in sales opportunities and projects';
																	|it = 'Ruoli delel controparti nelle transazioni e progetti';
																	|pl = 'Role kontrahentów w umowach i projektach';
																	|tr = 'Cari hesapların satış fırsatlarındaki ve projelerdeki rolleri'");
			TeamPartnerRolesInTransactionsAndProjects.ToolTip = 
			       NStr("vi = 'Bảng phân loại được dùng để xác định vai trò của đối tác tham gia trực tiếp hoặc gián tiếp vào vụ việc hoặc dự án.';
						|ru = 'Классификатор, используемый для понимания, какую роль выполняют косвенно или непосредственно участвующие в сделке или проекте контрагенты.';
						|en = 'Classifier used to identify roles of counterparties directly or indirectly involved in the sales opportunity or project.'; fa = 'Classifier used to identify roles of counterparties directly or indirectly involved in the sales opportunity or project.';
						|it = 'Un classificatore utilizzato per comprendere il ruolo dei partner, direttamente o indirettamente coinvolti in una transazione o in un progetto. della controparte.';
						|pl = 'Klasyfikator, który jest używany do zrozumienia, jaką rolę pełnią pośrednio lub bezpośrednio uczestniczące w umowie lub projekcie kontrahenci.';
						|tr = 'Satış fırsatındaki veya projedeki dolaylı veya doğrudan cari hesapların rolünün anlaşılması için kullanılan sınıflandırıcı.'");
		EndIf;
	EndIf;
	
	#EndRegion
	
	#Region PartnersAndContactPersons
	
	Items.GroupTheAccessGroupPartners.Visible = UsePartnerAccessGroups
		And AccessRightPartnerAccessGroups;
	Items.GroupRolesOfContactPersons.Visible = UseRolesOfPartnerContactPersons
		And RightOfAccessRolesOfPartnersContactPersons;
	Items.GroupBusinessRegions.Visible = UseBusinessRegions
		And RightOfAccessBusinessRegions;
	Items.GroupTypesOfPartnerRelationships.Visible = UsePartnerConnectionKinds
		And RightOfAccessTypesOfRelationsBetweenPartners;
		
	If Not Items.GroupRolesOfContactPersons.Visible Then
		If UsePartnersAsCounterparties Then
			Items.GroupPartnersContactPersons.Title = NStr("vi = 'Đối tác';
															|ru = 'Контрагенты';
															|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
															|it = 'Controparti';
															|pl = 'Counterparties';
															|tr = 'Cari hesaplar'");
		Else
			Items.GroupPartnersContactPersons.Title = NStr("vi = 'Bạn hàng';
															|ru = 'Партнеры';
															|en = 'Partners'; fa = 'شرکای تجاری';
															|it = 'Partner';
															|pl = 'Partners';
															|tr = 'İş ortakları'");
		EndIf;
	Else
		If UsePartnersAsCounterparties Then
			Items.GroupPartnersContactPersons.Title = NStr("vi = 'Đối tác và người liên hệ';
															|ru = 'Контрагенты и контактные лица';
															|en = 'Counterparties and contact persons'; fa = 'Counterparties and contact persons';
															|it = 'Contraenti e persone di riferimento';
															|pl = 'Kontrahenci i osoby do kontaktu';
															|tr = 'Cari hesaplar ve ilgili kişiler'");
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	           ThisObject, "SceneryCatalogRolesOfContactPersons",
	           NStr("vi = 'Dạng vai trò của người liên hệ mô tả hoạt động của người liên hệ trong doanh nghiệp của đối tác. Ví dụ, giám đốc, trưởng bộ phận, người quản lý.';
					|ru = 'Виды ролей контактных лиц, описывающих деятельность контактного лица на предприятии контрагента. Например, директор, руководитель отдела, менеджер.';
					|en = 'Contact person role kinds which describe a contact person''s activity in the counterparty''s company. For example: CEO, business unit manager, manager.'; fa = 'Contact person role kinds which describe a contact person''s activity in the counterparty''s company. For example: CEO, business unit manager, manager.';
					|it = 'Tipi di ruoli delle persone di contatto che descrivono le attività della persona di contatto presso l''impresa della controparte. Ad esempio, direttore, capo dipartimento, manager.';
					|pl = 'Rodzaje ról osób kontaktowych, które opisują działalność osoby kontaktowej w firmie kontrahenta. Na przykład, dyrektor, kierownik działu, kierownik.';
					|tr = 'Cari hesabın işletmesinde ilgili kişinin faaliyetlerini tanımlayan ilgili kişi rollerinin türleri. Örneğin: müdür, bölüm başkanı, yönetici.'"),
	           UsePartnersAsCounterparties);
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	           ThisObject, "CatalogPartnerAccessGroups",
	           NStr("vi = 'Nhóm truy cập đối tác.';
					|ru = 'Группы доступа контрагентов.';
					|en = 'Counterparty access groups.'; fa = 'Counterparty access groups.';
					|it = 'Gruppi di accesso delle controparti.';
					|pl = 'Grupy dostępu kontrahentów.';
					|tr = 'Cari hesap erişim grupları.'"),
	           UsePartnersAsCounterparties,
	           NStr("vi = 'Bảng phân loại để phân loại đối tác thành các nhóm mà có thể hạn chế quyền truy cập để xem, thêm (thay đổi) bạn hàng và truy cập chứng từ theo bạn hàng.';
					|ru = 'Классификатор деления контрагентов на группы, по которым можно ограничивать доступ на просмотр, добавление (изменение) партнеров и доступ к документам по партнерам.';
					|en = 'Classifier of counterparties'' division into groups that can be used to limit access to view, add (change) partners and access to partner documents.'; fa = 'Classifier of counterparties'' division into groups that can be used to limit access to view, add (change) partners and access to partner documents.';
					|it = 'Classificazione della divisione dei partner per gruppi mediante la quale è possibile limitare l''accesso alla visualizzazione, aggiungere (cambiare) i partner e accedere ai documenti da parte dei partner.';
					|pl = 'Klasyfikacja podziału kontrahentów na grupy, dzięki której możliwe jest ograniczenie dostępu do przeglądania, dodawania (zmiany) partnerów i dostępu do dokumentów przez partnerów. ';
					|tr = 'Cari hesapları görüntüleme, iş ortağı ekleme (değiştirme) ve iş ortağı belgelerine erişimin kısıtlanabileceği, gruplara ayıran sınıflandırıcı.'"));
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	           ThisObject, "CatalogPartnerAccessGroups",
	           NStr("vi = 'Nhóm truy cập đối tác.';
					|ru = 'Группы доступа контрагентов.';
					|en = 'Counterparty access groups.'; fa = 'Counterparty access groups.';
					|it = 'Gruppi di accesso delle controparti.';
					|pl = 'Grupy dostępu kontrahentów.';
					|tr = 'Cari hesap erişim grupları.'"),
	           UsePartnersAsCounterparties);
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	           ThisObject, "DecorationCatalogOfPartnerAccessGroups",
	           NStr("vi = 'Bảng phân loại để phân loại đối tác thành các nhóm, mà có thể hạn chế truy cập để xem, thêm (thay đổi) đối tác và truy cập đến chứng từ theo đối tác.';
					|ru = 'Классификатор деления контрагентав на группы, по которым можно ограничивать доступ на просмотр, добавление (изменение) контрагентов и доступ к документам по контрагентам.';
					|en = 'Classifier of counterparties'' division into groups that can be used to limit access to view, add (change) counterparties and access to counterparty documents.'; fa = 'Classifier of counterparties'' division into groups that can be used to limit access to view, add (change) counterparties and access to counterparty documents.';
					|it = 'Classificatore della divisione delle controparti in gruppi mediante il quale è possibile limitare l''accesso alla visualizzazione, all''aggiunta (modifica) delle controparti e all''accesso ai documenti per controparti.';
					|pl = 'Klasyfikator podziału kontrahentów na grupy, w których można ograniczać dostęp na przeglądanie, dodawanie (zmianę) kontrahentów i dostęp do dokumentów kontrahentom.';
					|tr = 'Cari hesapları görüntüleme, cari hesap ekleme (değiştirme) ve cari hesap belgelerine erişimin kısıtlanabileceği, gruplara ayıran sınıflandırıcı.'"),
	           UsePartnersAsCounterparties);
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	           ThisObject, "ReferenceTypesOfPartnerRelationships",
	           NStr("vi = 'Dạng quan hệ của đối tác.';
					|ru = 'Виды связей контрагентов.';
					|en = 'Types of relationship between counterparties.'; fa = 'Types of relationship between counterparties.';
					|it = 'Tipi di relazioni delle controparti.';
					|pl = 'Rodzaje więzi kontrahentów.';
					|tr = 'Cari hesapların ilişki türleri.'"),
	           UsePartnersAsCounterparties);
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	           ThisObject, "DecorationTypesOfRelationsOfPartners",
	           NStr("vi = 'Bảng phân loại các dạng vụ việc kinh doanh, mà có thể tùy chỉnh giữa các đối tác của doanh nghiệp thương mại.';
					|ru = 'Классификатор видов деловых связей , которые могут быть настроены между контрагентами торгового предприятия.';
					|en = 'Classifier of types of business relations that can be set between partners of a trading enterprise.'; fa = 'Classifier of types of business relations that can be set between partners of a trading enterprise.';
					|it = 'Classificatore di tipi connessioni aziendali che possono essere creati tra le controparti dell''impresa commerciale.';
					|pl = 'Klasyfikator rodzajów więzi biznesowych , które mogą być dostosowane między kontrahentami przedsiębiorstwa handlowego.';
					|tr = 'Ticari işletmenin cari hesapları arasında yapılandırılabilen iş ilişkisi türlerine yönelik sınıflandırıcı.'"),
	           UsePartnersAsCounterparties);
	
	Items.OpenContactInformationKinds.Visible = RightOfAccessTypesOfContactInformation;
	
	#EndRegion
	
	#Region Complaints
	
	Items.TheGroupClaims.Visible = RecordCustomerClaims And RightOfAccessReasonsForClaims;
	
	#EndRegion
	
EndProcedure

#Region Other

&AtServerNoContext
Function PriceTypePriceList_()
	
	Return PriceManagementSystem.PriceTypePriceList_();
	
EndFunction

&AtClient
Procedure OpenPriceGroups(Command)

	OpenForm("Catalog.PriceGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenItemSalesRatings(Command)
	
	OpenForm("Catalog.SalesRanks.ListForm",, ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheSetAssociations(Command)
	
	OpenForm("InformationRegister.ProductsSoldTogether.Form.SettingOfAssociationSearch", Undefined);
	
EndProcedure

&AtClient
Procedure OpenTheItemsSoldTogether(Command)
	
	OpenForm("InformationRegister.ProductsSoldTogether.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#EndRegion
