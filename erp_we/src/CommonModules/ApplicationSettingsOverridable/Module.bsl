///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The procedure is intended to make changes to the SupportAndService form of the
// SSLAdministrationPanel data processor without removing the form from support.
//
// Parameters:
//  Form - ClientApplicationForm - a form to be changed.
//
Procedure ServiceOnCreateAtServer(Form) Export
	Form.Items.ReportsAndDataProcessorsGroup.Visible = Not GetFunctionalOption("BaseVersion");
EndProcedure

// The procedure is intended to make changes to the CommonSettings form of the
// SSLAdministrationPanel data processor without removing the form from support.
//
// Parameters:
//  Form - ClientApplicationForm - a form to be changed.
//
Procedure CommonSettingsOnCreateAtServer(Form) Export
	
EndProcedure

// The procedure is intended to make changes to the SupportAndService form of the
// SSLAdministrationPanel data processor without removing the form from support.
//
// Parameters:
//  Form - ClientApplicationForm - a form to be changed.
//
Procedure UsersAndRightsSettingsOnCreateAtServer(Form) Export
	BaseVersion = GetFunctionalOption("BaseVersion");
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	CompositionOfSetOfConstantsOfForm = TMCommonUse.GetStructureOfSetOfConstants(Form.ConstantsSet);
	
	Form.Items.AccessGroupsProfilesAndRecordLevelRestrictionGroup.Visible 		= Not BaseVersion;
	Form.Items.UsePartnerAccessGroupsGroup.Visible 	= Not BaseVersion;
	Form.Items.UseItemAccessGroupsGroup.Visible 	= Not BaseVersion;
	Form.Items.CopyUsersSettingsGroup.Visible 		= Not BaseVersion;
	Form.Items.ClearUsersSettingsGroup.Visible			= BaseVersion;
	Form.Items.GroupUserMonitoringRightColumn.Visible = Not BaseVersion;
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	      Form, "UsePartnerAccessGroups",
	      NStr("vi = 'Nhóm truy cập đối tác';
				|ru = 'Группы доступа контрагентов';
				|en = 'Counterparty access groups'; fa = 'Counterparty access groups';
				|it = 'Gruppi d''accesso dei contraenti';
				|pl = 'Grupy dostępu kontrahentów';
				|tr = 'Cari hesap erişim grupları'"), UsePartnersAsCounterparties);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	      Form, "ExplanationUsePartnerAccessGroups",
	      NStr("vi = 'Phân chia đối tác thành các nhóm mà có thể ấn định cho người sử dụng quyền bổ sung (thay đổi), xem đối tác và tất cả chứng từ theo đối tác này.';
				|ru = 'Деление контрагентов на группы, по которым можно назначать пользователям права на добавление (изменение), просмотр контрагентов и всех документов по этим контрагентам.';
				|en = 'Dividing counterparties into groups that can be used to grant user rights to add (edit) and view all counterparties and their documents.'; fa = 'Dividing counterparties into groups that can be used to grant user rights to add (edit) and view all counterparties and their documents.';
				|it = 'Divisione dei contraenti in gruppi in cui è possibile assegnare agli utenti i diritti di aggiunta (modifica), visualizzazione dei contraenti e di tutti i documenti di tali controparti.';
				|pl = 'Podział kontrahentów na grupy, wg których można udzielać użytkownikom prawa do dodania (zmiany), przeglądu kontrahentów i wszystkich dokumentów wg tych kontrahentów.';
				|tr = 'Cari hesapları, kullanıcılara ekleme (değiştirme), cari hesapları ve onlara ait tüm belgeleri görüntüleme yetkilerinin atanabileceği gruplara ayır.'"),
	      UsePartnersAsCounterparties);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	      Form, "OpenPartnerAccessGroups",
	      NStr("vi = 'Nhóm truy cập đối tác';
				|ru = 'Группы доступа контрагентов';
				|en = 'Counterparty access groups'; fa = 'Counterparty access groups';
				|it = 'Gruppi d''accesso dei contraenti';
				|pl = 'Grupy dostępu kontrahentów';
				|tr = 'Cari hesap erişim grupları'"), UsePartnersAsCounterparties);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	      Form, "ExplanationOpenPartnerAccessGroups",
	      NStr("vi = 'Tạo nhóm truy cập đối tác.';
				|ru = 'Создание групп доступа контрагентов.';
				|en = 'Create access groups of counterparties.'; fa = 'Create access groups of counterparties.';
				|it = 'Creazione di gruppi d''accesso dei contraenti.';
				|pl = 'Utworzenie grup dostępu kontrahentów.';
				|tr = 'Cari hesap erişim gruplarının oluşturulması'"), UsePartnersAsCounterparties);
	
	UseBudgeting = GetFunctionalOption("UseBudgeting");
	Form.Items.GroupUseAccessGroupsOfItemKindsAndBudgetIndicators.Visible = UseBudgeting;
	
	CommonClientServer.SetFormItemProperty(Form.Items, "UsePersonalDataHiding", "Enabled", False);
	ApplicationSettingsLocalization.UsersAndRightsSettingsOnCreateAtServer(Form);
EndProcedure

// The procedure is intended to make changes to the InternetSupportAndServices form of the
// SSLAdministrationPanel data processor without removing the form from support.
//
// Parameters:
//  Form - ClientApplicationForm - a form to be changed.
//
Procedure OnlineSupportAndServicesOnCreateAtServer(Form) Export
	
EndProcedure

// The procedure is intended to make changes to the Organizer form of the
// SSLAdministrationPanel data processor without removing the form from support.
//
// Parameters:
//  Form - ClientApplicationForm - a form to be changed.
//
Procedure OrganizerOnCreateAtServer(Form) Export
	
EndProcedure

// The procedure is intended to make changes to the DataSynchronization form of the
// SSLAdministrationPanel data processor without removing the form from support.
//
// Parameters:
//  Form - ClientApplicationForm - a form to be changed.
//
Procedure DataSynchronizationOnCreateAtServer(Form) Export
	
EndProcedure

// The procedure is intended to make changes to the FilesOperationsSettings form of the
// SSLAdministrationPanel data processor without removing the form from support.
//
// Parameters:
//  Form - ClientApplicationForm - a form to be changed.
//
Procedure FilesOperationSettingsOnCreateAtServer(Form) Export
	
EndProcedure

// The procedure is intended to make changes to the PrintFormsReportsAndDataProcessors form of the
// SSLAdministrationPanel data processor without removing the form from support.
//
// Parameters:
//  Form - ClientApplicationForm - a form to be changed.
//
Procedure PrintFormsReportsAndDataProcessorsOnCreateAtServer(Form) Export
	
	ApplicationSettingsLocalization.PrintFormsReportsAndDataProcessorsOnCreateAtServer(Form);
		
EndProcedure

#EndRegion