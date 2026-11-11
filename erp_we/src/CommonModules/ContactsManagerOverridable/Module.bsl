///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Changes, adds, or deletes contact information standard commands displayed in catalogs and documents.
// Toggles contact information icons on the left of the contact information kind title.
// Changes the position of the button "Add additional contact information field".
// Changes the width of the comment field for the contact information of the kinds
// "Phone", "Email", "Skype", "WebPage", and "Fax".
//
// Parameters:
//  Settings - Structure:
//    * ShouldShowIcons - Boolean
//    * DetailsOfCommands - See ContactsManager.DetailsOfCommands
//    * PositionOfAddButton - ItemHorizontalLocation - Valid values are Left, Right, or Auto.
//                                                                  If set to Left, it always appears on the left.
//                                                                  If set to Right, it always appears on the right.
//                                                                  If set to Auto, it is positioned on the right if
//                                                                         contact information is a field
//                                                                         and on the left if contact information is a hyperlink
//                                                                         or if there is no contact information field.
//                                                                         
//    * CommentFieldWidth - Number - Comment field width for contact information fields of the following types: Phone, Email,
//                                      Skype, WebPage, and Fax. This parameter is set only if the contact
//                                      information group is limited in width.
//
//  Example:
//     Settings.ShouldShowIcons = True;
//     Settings.CommentFieldWidth = 10;
//     Settings.PositionOfAddButton = ItemHorizontalLocation.Auto;
//
//     Address = Enums.ContactInformationTypes.Address;
//     Settings.DetailsOfCommands[Address].PlanMeeting.Title = NStr("ru='Meeting'");
//     Settings.DetailsOfCommands[Address].PlanMeeting.ToolTip = NStr("en='Schedule a meeting.'; fa = 'Schedule a meeting.'");
//     Settings.DetailsOfCommands[Address].PlanMeeting.Picture = PictureLib.PlannedInteraction;
//     Settings.DetailsOfCommands[Address].PlanMeeting.Action = "StandardSubsystemsClient.OpenMeetingDocForm";
//    
//     CompanyPhysicalAddress = ContactsManager.ContactInformationKindByName("CompanyPhysicalAddress");
//      Settings.DetailsOfCommands[CompanyPhysicalAddress] = 
//    	Common.CopyRecursive(ContactsManager.CommandsOfContactInfoType(Enums.ContactInformationTypes.Address));
//      Settings.DetailsOfCommands[CompanyPhysicalAddress].PlanMeeting.Action = ""; // Disable the command for the contact information kind.
//
//   2 parameters are passed to the procedures specified in "Action":
//       ContactInformation - Structure:
//         * Presentation - String
//         * Value - String
//         * Type - EnumRef.ContactInformationTypes
//         * Kind - CatalogRef.ContactInformationKinds
//       AdditionalParameters - Structure:        
//         * ContactInformationOwner - DefinedType.ContactInformationOwner.
//         * Form - ClientApplicationForm - Form of the owner object, where the contact information is to be displayed.
// 
//     Procedure OpenMeetingDocForm(ContactInformation, AdditionalParameters) Export
//		  FillingValues = New Structure;
//		  FillingValues.Insert("MeetingPlace", ContactInformation.Presentation);
//		  If TypeOf(AdditionalParameters.ContactInformationOwner) = Type("DocumentRef.SalesOrder") Then
//		    	FillingValues.Insert("SubjectOf", AdditionalParameters.ContactInformationOwner);
//		    	FillingValues.Insert("Contact", "");
//		  Else
//		    	FillingValues.Insert("Contact", AdditionalParameters.ContactInformationOwner);
//		    	FillingValues.Insert("SubjectOf", "");
//		  EndIf;
//
//		  OpenForm("Document.Meeting.ObjectForm", New Structure("FillingValues", FillingValues),
//			AdditionalParameters.Form);
//	   EndProcedure
//
Procedure OnDefineSettings(Settings) Export

	
    
EndProcedure

// Gets descriptions of contact information kinds in different languages.
//
// Parameters:
//  Descriptions - Map of KeyAndValue - a presentation of a contact information kind in the passed language:
//     * Key     - String - The name of a contact information kind. For example, "PartnerAddress".
//     * Value - String - a description of a contact information kind for the passed language code.
//  LanguageCode - String - a language code. For example, "en".
//
// Example:
//  Descriptions["PartnerAddress"] = NStr("ru='
//
Procedure OnGetContactInformationKindsDescriptions(Descriptions, LanguageCode) Export
	
	Descriptions["CatalogContactPersonsForPartners"] = NStr("vi = 'Thông tin liên hệ của danh mục ""Người liên hệ của đối tác""';
															|ru = 'Контактная информация справочника ""Контактные лица партнеров""';
															|en = 'Contact information in the ""Partner contacts"" catalog'; fa = 'Contact information in the ""Partner contacts"" catalog';
															|it = 'Informazioni di contatto della query ""Contatti dei partner""';
															|pl = 'Dane kontaktowe katalogu „Osoby kontaktowe partnerów”';
															|tr = '""Ortakların İrtibat Kişileri"" dizininin iletişim bilgileri'", LanguageCode);
	Descriptions["ContactPersonSMobilePhoneNumber"] = NStr("vi = 'Điện thoại di động';
															|ru = 'Мобильный телефон';
															|en = 'Cell phone'; fa = 'تلفن همراه';
															|it = 'Numero di telefono cellulare';
															|pl = 'Telefon komórkowy';
															|tr = 'Cep telefonu'", LanguageCode);
	Descriptions["ContactPersonSPhoneNumber"] = NStr("vi = 'Điện thoại';
													|ru = 'Телефон';
													|en = 'Phone'; fa = 'تلفن';
													|it = 'Telefono';
													|pl = 'Telefon';
													|tr = 'Telefon'", LanguageCode);
	Descriptions["EmailContactPerson"] = NStr("vi = 'Email';
												|ru = 'Электронная почта';
												|en = 'Email'; fa = 'ایمیل';
												|it = 'Posta elettronica';
												|pl = 'Poczta elektroniczna';
												|tr = 'E-posta'", LanguageCode);
	Descriptions["CatalogCounterparties"] = NStr("vi = 'Thông tin liên hệ của danh mục ""Đối tác""';
												|ru = 'Контактная информация справочника ""Контрагенты""';
												|en = 'Contact details in the ""Counterparties"" catalog'; fa = 'Contact details in the ""Counterparties"" catalog';
												|it = 'Informazioni di contatto della query ""Controparti""';
												|pl = 'Dane kontaktowe katalogu ""Kontrahenci""';
												|tr = '""Cari hesaplar"" dizininin iletişim bilgileri'", LanguageCode);
	Descriptions["OtherInformationOfCounterparties"] = NStr("vi = 'Khác (thông tin liên hệ khác bất kỳ)';
															|ru = 'Другое (любая другая контактная информация)';
															|en = 'Other (any other contact details )'; fa = 'Other (any other contact details )';
															|it = 'Altro (qualsiasi altra informazione di contatto)';
															|pl = 'Inne (inna informacja kontaktowa)';
															|tr = 'Diğer (başka herhangi iletişim bilgileri)'", LanguageCode);
	Descriptions["InternationalAddressOfCounterparty"] = NStr("vi = 'Địa chỉ quốc tế để thanh toán (Anh.)';
																|ru = 'Международный адрес для платежей (англ.)';
																|en = 'International address for payments (eng.)'; fa = 'International address for payments (eng.)';
																|it = 'Indirizzo internazionale per i pagamenti (eng.)';
																|pl = 'Międzynarodowy adres płatniczy (ang.)';
																|tr = 'Uluslararası ödeme adresi (ing.)'", LanguageCode);
	Descriptions["PostalAddressOfCounterparty"] = NStr("vi = 'Địa chỉ bưu điện';
														|ru = 'Почтовый адрес';
														|en = 'Postal address'; fa = 'Postal address';
														|it = 'Indirizzo postale';
														|pl = 'Adres pocztowy';
														|tr = 'Posta adresi'", LanguageCode);
	Descriptions["CounterpartySPhoneNumber"] = NStr("vi = 'Điện thoại';
													|ru = 'Телефон';
													|en = 'Phone'; fa = 'تلفن';
													|it = 'Telefono';
													|pl = 'Telefon';
													|tr = 'Telefon'", LanguageCode);
	Descriptions["FaxCounterparties"] = NStr("vi = 'Fax';
											|ru = 'Факс';
											|en = 'Fax'; fa = 'فکس';
											|it = 'Fax';
											|pl = 'Faks';
											|tr = 'Faks'", LanguageCode);
	Descriptions["ActualDataCounterpartyAddress"] = NStr("vi = 'Địa chỉ thực tế';
														|ru = 'Фактический адрес';
														|en = 'Business address'; fa = 'آدرس کسب‌وکار';
														|it = 'Sede operativa';
														|pl = 'Adres faktyczny';
														|tr = 'Gerçek adres'", LanguageCode);
	Descriptions["EmailCounterparty_"] = NStr("vi = 'Email';
												|ru = 'Электронная почта';
												|en = 'Email'; fa = 'ایمیل';
												|it = 'Posta elettronica';
												|pl = 'Poczta elektroniczna';
												|tr = 'E-posta'", LanguageCode);
	Descriptions["LegalAddressOfCounterparty"] = NStr("vi = 'Địa chỉ đăng ký';
														|ru = 'Юридический адрес';
														|en = 'Legal address'; fa = 'آدرس قانونی';
														|it = 'Sede legale';
														|pl = 'Adres prawny';
														|tr = 'Yasal adres'", LanguageCode);
	Descriptions["CatalogCompanies"] = NStr("vi = 'Thông tin liên hệ của danh mục ""Doanh nghiệp""';
											|ru = 'Контактная информация справочника ""Организации""';
											|en = 'Contact details in the ""Companies"" catalog'; fa = 'Contact details in the ""Companies"" catalog';
											|it = 'Informazioni di contatto della query ""Azienda""';
											|pl = 'Dane kontaktowe katalogu „Firmy”';
											|tr = '""İş yeri"" dizininin iletişim bilgileri'", LanguageCode);
	Descriptions["OtherInformationOfCompany"] = NStr("vi = 'Khác';
													|ru = 'Другое';
													|en = 'Other'; fa = 'سایر';
													|it = 'Altro';
													|pl = 'Other';
													|tr = 'Diğer'", LanguageCode);
	Descriptions["InternationalAddressOfCompany"] = NStr("vi = 'Địa chỉ quốc tế để thanh toán (Anh.)';
														|ru = 'Международный адрес для платежей (англ.)';
														|en = 'International address for payments (eng.)'; fa = 'International address for payments (eng.)';
														|it = 'Indirizzo internazionale per i pagamenti (eng.)';
														|pl = 'Międzynarodowy adres płatniczy (ang.)';
														|tr = 'Uluslararası ödeme adresi (ing.)'", LanguageCode);
	Descriptions["CompanyPostalAddress"] = NStr("vi = 'Địa chỉ bưu điện';
												|ru = 'Почтовый адрес';
												|en = 'Postal address'; fa = 'Postal address';
												|it = 'Indirizzo postale';
												|pl = 'Adres pocztowy';
												|tr = 'Posta adresi'", LanguageCode);
	Descriptions["CompanyPhone"] = NStr("vi = 'Điện thoại';
										|ru = 'Телефон';
										|en = 'Phone'; fa = 'تلفن';
										|it = 'Telefono';
										|pl = 'Telefon';
										|tr = 'Telefon'", LanguageCode);
	Descriptions["CompanyFax"] = NStr("vi = 'Fax';
										|ru = 'Факс';
										|en = 'Fax'; fa = 'فکس';
										|it = 'Fax';
										|pl = 'Faks';
										|tr = 'Faks'", LanguageCode);
	Descriptions["ActualDataAddressOfCompany"] = NStr("vi = 'Địa chỉ thực tế';
														|ru = 'Фактический адрес';
														|en = 'Business address'; fa = 'آدرس کسب‌وکار';
														|it = 'Sede operativa';
														|pl = 'Adres faktyczny';
														|tr = 'Gerçek adres'", LanguageCode);
	Descriptions["EmailCompanies"] = NStr("vi = 'Email';
											|ru = 'Электронная почта';
											|en = 'Email'; fa = 'ایمیل';
											|it = 'Posta elettronica';
											|pl = 'Poczta elektroniczna';
											|tr = 'E-posta'", LanguageCode);
	Descriptions["LegalAddressOfCompany"] = NStr("vi = 'Địa chỉ đăng ký';
												|ru = 'Юридический адрес';
												|en = 'Legal address'; fa = 'آدرس قانونی';
												|it = 'Sede legale';
												|pl = 'Adres prawny';
												|tr = 'Yasal adres'", LanguageCode);
	Descriptions["CatalogPartners"] = NStr("vi = 'Thông tin liên lạc của danh mục ""Bạn hàng""';
											|ru = 'Контактная информация справочника ""Партнеры""';
											|en = 'Contact details in the ""Partners"" catalog'; fa = 'Contact details in the ""Partners"" catalog';
											|it = 'Informazioni di contatto della query ""Partner""';
											|pl = 'Dane kontaktowe katalogu „Partnerzy”';
											|tr = '""Ortaklar"" dizininin iletişim bilgileri'", LanguageCode);
	Descriptions["PartnerAddress"] = NStr("vi = 'Địa chỉ';
											|ru = 'Адрес';
											|en = 'Address'; fa = 'آدرس';
											|it = 'Indirizzo';
											|pl = 'Adres';
											|tr = 'Adres'", LanguageCode);
	Descriptions["PartnerSPhoneNumber"] = NStr("vi = 'Điện thoại';
												|ru = 'Телефон';
												|en = 'Phone'; fa = 'تلفن';
												|it = 'Telefono';
												|pl = 'Telefon';
												|tr = 'Telefon'", LanguageCode);
	Descriptions["EmailPartner_"] = NStr("vi = 'Email';
										|ru = 'Электронная почта';
										|en = 'Email'; fa = 'ایمیل';
										|it = 'Posta elettronica';
										|pl = 'Poczta elektroniczna';
										|tr = 'E-posta'", LanguageCode);
	Descriptions["CatalogUsers"] = NStr("vi = 'Thông tin liên hệ của danh mục ""Người sử dụng""';
										|ru = 'Контактная информация справочника ""Пользователи""';
										|en = 'Contact details in ""Users"" catalog'; fa = 'Contact details in ""Users"" catalog';
										|it = 'Informazioni di contatto della query ""Utenti""';
										|pl = 'Dane kontaktowe katalogu ""Użytkownicy""';
										|tr = '""Kullanıcılar"" dizininin iletişim bilgileri'", LanguageCode);
	Descriptions["UserPhone"] = NStr("vi = 'Điện thoại';
									|ru = 'Телефон';
									|en = 'Phone'; fa = 'تلفن';
									|it = 'Telefono';
									|pl = 'Telefon';
									|tr = 'Telefon'", LanguageCode);
	Descriptions["UserEmail"] = NStr("vi = 'Email';
									|ru = 'Электронная почта';
									|en = 'Email'; fa = 'ایمیل';
									|it = 'Posta elettronica';
									|pl = 'Poczta elektroniczna';
									|tr = 'E-posta'", LanguageCode);
	Descriptions["CatalogRegistrationsInTaxAuthority"] = NStr("vi = 'Thông tin liên hệ của danh mục ""Đăng ký với cơ quan thuế""';
																|ru = 'Контактная информация справочника ""Регистрации в налоговом органе""';
																|en = 'Contact details in the ""Registrations with tax authority"" catalog'; fa = 'Contact details in the ""Registrations with tax authority"" catalog';
																|it = 'Informazioni di contatto della query ""Registrazione presso l''autorità fiscale""';
																|pl = 'Dane kontaktowe katalogu „Rejestracja w urzędzie skarbowym”';
																|tr = '""Vergi dairesinde kayıt"" kataloğunun iletişim bilgileri'", LanguageCode);
	Descriptions["TaxAuthorityAddress"] = NStr("vi = 'Địa chỉ cơ quan thuế';
												|ru = 'Адрес налогового органа';
												|en = 'Tax authority address'; fa = 'Tax authority address';
												|it = 'Indirizzo dell''autorità fiscale';
												|pl = 'Adres urzędu skarbowego';
												|tr = 'Vergi dairesi adresi'", LanguageCode);
	Descriptions["TaxAuthorityPhone"] = NStr("vi = 'Điện thoại của cơ quan thuế';
											|ru = 'Телефон налогового органа';
											|en = 'Tax authority phone'; fa = 'Tax authority phone';
											|it = 'Telefono dell''autortià fiscale';
											|pl = 'Telefon urzędu skarbowego';
											|tr = 'Vergi dairesi telefonu'", LanguageCode);
	Descriptions["ActualAddressOfBranchOffice"] = NStr("vi = 'Địa chỉ thực tế của đơn vị độc lập';
														|ru = 'Фактический адрес обособленного подразделения';
														|en = 'Branch office business address'; fa = 'Branch office business address';
														|it = 'Indirizzo effettivo del reparto esterno';
														|pl = 'Aktualny adres oddzielnego działu';
														|tr = 'Ayrı departmanın iş adresi'", LanguageCode);
	Descriptions["CatalogWarehouses"] = NStr("vi = 'Thông tin liên hệ của danh mục ""Kho bãi""';
											|ru = 'Контактная информация справочника ""Склады""';
											|en = 'Contact details in the ""Warehouses"" catalog'; fa = 'Contact details in the ""Warehouses"" catalog';
											|it = 'Informazioni di contatto della query ""Magazzini""';
											|pl = 'Informacje kontaktowe katalogu „Magazyny”';
											|tr = '""Ambarlar"" kataloğunun iletişim bilgileri'", LanguageCode);
	Descriptions["WarehouseAddress"] = NStr("vi = 'Địa chỉ kho';
											|ru = 'Адрес склада';
											|en = 'Warehouse address'; fa = 'آدرس انبار';
											|it = 'Indirizzo magazzino';
											|pl = 'Adres magazynu';
											|tr = 'Ambar adresi'", LanguageCode);
	Descriptions["WarehousePhone"] = NStr("vi = 'Điện thoại kho';
											|ru = 'Телефон склада';
											|en = 'Warehouse phone'; fa = 'Warehouse phone';
											|it = 'Telefono magazzino';
											|pl = 'Telefon magazynu';
											|tr = 'Ambar telefonu'", LanguageCode);
	Descriptions["CatalogRetailOutlets"] = NStr("vi = 'Thông tin liên hệ của danh mục ""Điểm bán hàng""';
												|ru = 'Контактная информация справочника ""Торговые точки""';
												|en = 'Contact details in the ""Sales outlets"" catalog'; fa = 'Contact details in the ""Sales outlets"" catalog';
												|it = 'Informazioni di contatto della query ""Punti vendita""';
												|pl = 'Informacje kontaktowe katalogu „Punkty sprzedaży”';
												|tr = '""Satış noktaları"" kataloğunun iletişim bilgileri'", LanguageCode);
	Descriptions["OutletAddress"] = NStr("vi = 'Địa chỉ';
										|ru = 'Адрес';
										|en = 'Address'; fa = 'آدرس';
										|it = 'Indirizzo';
										|pl = 'Address';
										|tr = 'Adres'", LanguageCode);
	Descriptions["CatalogPersons"] = NStr("vi = 'Thông tin liên hệ của danh mục ""Cá nhân""';
											|ru = 'Контактная информация справочника ""Физические лица""';
											|en = 'Contact details from the ""Persons"" catalog'; fa = 'Contact details from the ""Persons"" catalog';
											|it = 'Informazioni di contatto della query ""Persone fisiche""';
											|pl = 'Informacje kontaktowe katalogu „Osoby fizyczne”';
											|tr = '""Gerçek kişiler"" kataloğunun iletişim bilgileri'", LanguageCode);
	Descriptions["AddressForInformingPersons"] = NStr("vi = 'Địa chỉ để thông tin hóa';
														|ru = 'Адрес для информирования';
														|en = 'Notice address'; fa = 'Notice address';
														|it = 'Indirizzo per informazioni';
														|pl = 'Adres do informowania';
														|tr = 'Bilgilendirme adresi'", LanguageCode);
	Descriptions["AddressOutsideRussianFederationPersons"] = NStr("vi = 'Địa chỉ nước ngoài';
																	|ru = 'Иностранный адрес';
																	|en = 'Foreign address'; fa = 'Foreign address';
																	|it = 'Indirizzo straniero';
																	|pl = 'Adres zagraniczny';
																	|tr = 'Yabancı adres'", LanguageCode);
	Descriptions["ResidentialAddressPersons"] = NStr("vi = 'Địa chỉ cư trú';
													|ru = 'Адрес места проживания';
													|en = 'Residential address'; fa = 'Residential address';
													|it = 'Indirizzo di residenza';
													|pl = 'Adres miejsca zamieszkania';
													|tr = 'Yerleşim yeri'", LanguageCode);
	Descriptions["RegistrationAddressPersons"] = NStr("vi = 'Địa chỉ đăng ký';
														|ru = 'Адрес по прописке';
														|en = 'Registration address'; fa = 'آدرس ثبت‌نام';
														|it = 'Indirizzo di registrazione';
														|pl = 'Adres zameldowania';
														|tr = 'İkametgah'", LanguageCode);
	Descriptions["HomePhoneNumberOfPerson"] = NStr("vi = 'Điện thoại nhà riêng';
													|ru = 'Домашний телефон';
													|en = 'Home phone'; fa = 'Home phone';
													|it = 'Telefono (casa)';
													|pl = 'Telefon domowy';
													|tr = 'Ev telefonu'", LanguageCode);
	Descriptions["MobilePhoneOfPerson"] = NStr("vi = 'Điện thoại di động';
												|ru = 'Мобильный телефон';
												|en = 'Cell phone'; fa = 'تلفن همراه';
												|it = 'Numero di telefono cellulare';
												|pl = 'Telefon komórkowy';
												|tr = 'Cep telefonu'", LanguageCode);
	Descriptions["WorkingPhoneNumberOfPerson"] = NStr("vi = 'Điện thoại công việc';
														|ru = 'Рабочий телефон';
														|en = 'Work phone'; fa = 'Work phone';
														|it = 'Numero di telefono dell''ufficio';
														|pl = 'Telefon miejsca pracy';
														|tr = 'İş telefonu'", LanguageCode);
	Descriptions["EMailPersons"] = NStr("vi = 'Email';
										|ru = 'Электронная почта';
										|en = 'Email'; fa = 'ایمیل';
										|it = 'Posta elettronica';
										|pl = 'Poczta elektroniczna';
										|tr = 'E-posta'", LanguageCode);
	
EndProcedure

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	Item = Items.Add();
	Item.PredefinedDataName = "OutletAddress";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogRetailOutlets;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ';
																					|ru = 'Адрес';
																					|en = 'Address';
																					|it = 'Адрес';
																					|pl = 'Adres';
																					|tr = 'Adres'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "Address";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "ContactPersonSMobilePhoneNumber";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogContactPersonsForPartners;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại di động';
																					|ru = 'Мобильный телефон';
																					|en = 'Cell phone';
																					|it = 'Numero di telefono cellulare';
																					|pl = 'Telefon komórkowy';
																					|tr = 'Cep telefonu'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "MobilePhone";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "ContactPersonSPhoneNumber";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogContactPersonsForPartners;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại';
																					|ru = 'Телефон';
																					|en = 'Phone';
																					|it = 'Телефон';
																					|pl = 'Telefon';
																					|tr = 'Telefon'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "Phone";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "EmailContactPerson";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogContactPersonsForPartners;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'E-mail';
																					|ru = 'Электронная почта';
																					|en = 'Email';
																					|it = 'Posta elettronica';
																					|pl = 'Poczta elektroniczna';
																					|tr = 'E-posta'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputField";
	Item.DenyEditingByUser = False;
	Item.IDForFormulas = "Email";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Email;

	Item = Items.Add();
	Item.PredefinedDataName = "OtherInformationOfCounterparties";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCounterparties;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Khác (thông tin liên hệ khác bất kỳ)';
																					|ru = 'Другое (любая другая контактная информация)';
																					|en = 'Other (any other contact details )';
																					|it = 'Altro (qualsiasi altra informazione di contatto)';
																					|pl = 'Inne (inna informacja kontaktowa)';
																					|tr = 'Diğer (başka herhangi iletişim bilgileri)'", LanguagesCodes); // @NStr-2
	Item.FieldKindOther = "MultilineWide";
	Item.EditingOption = "InputField";
	Item.IDForFormulas = "OtherAnyOtherContactDetails";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Other;

	Item = Items.Add();
	Item.PredefinedDataName = "InternationalAddressOfCounterparty";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCounterparties;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ quốc tế để thanh toán (Anh.)';
																					|ru = 'Международный адрес для платежей (англ.)';
																					|en = 'International address for payments (eng.)';
																					|it = 'Indirizzo internazionale per i pagamenti (eng.)';
																					|pl = 'Międzynarodowy adres płatniczy (ang.)';
																					|tr = 'Uluslararası ödeme adresi (ing.)'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "InternationalAddressForPaymentsEnglish";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "PostalAddressOfCounterparty";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCounterparties;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ bưu điện';
																					|ru = 'Почтовый адрес';
																					|en = 'Postal address';
																					|it = 'Indirizzo postale';
																					|pl = 'Adres pocztowy';
																					|tr = 'Posta adresi'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "MailAddress";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "CounterpartySPhoneNumber";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCounterparties;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại';
																					|ru = 'Телефон';
																					|en = 'Phone';
																					|it = 'Телефон';
																					|pl = 'Telefon';
																					|tr = 'Telefon'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "Phone";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "FaxCounterparties";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCounterparties;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Fax';
																					|ru = 'Факс';
																					|en = 'Fax';
																					|it = 'Факс';
																					|pl = 'Faks';
																					|tr = 'Faks'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "Fax";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Fax;

	Item = Items.Add();
	Item.PredefinedDataName = "ActualDataCounterpartyAddress";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCounterparties;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ thực tế';
																					|ru = 'Фактический адрес';
																					|en = 'Business address';
																					|it = 'Sede operativa';
																					|pl = 'Adres faktyczny';
																					|tr = 'İş adresi'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "ActualAddress";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "EmailCounterparty_";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCounterparties;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'E-mail';
																					|ru = 'Электронная почта';
																					|en = 'Email';
																					|it = 'Posta elettronica';
																					|pl = 'Poczta elektroniczna';
																					|tr = 'E-posta'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputField";
	Item.IDForFormulas = "Email";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Email;

	Item = Items.Add();
	Item.PredefinedDataName = "LegalAddressOfCounterparty";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCounterparties;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ đăng ký';
																					|ru = 'Юридический адрес';
																					|en = 'Legal address';
																					|it = 'Sede legale';
																					|pl = 'Adres prawny';
																					|tr = 'Yasal adres'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "LegalAddress";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "OtherInformationOfCompany";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCompanies;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Khác (thông tin liên hệ khác bất kỳ)';
																					|ru = 'Другое (любая другая контактная информация)';
																					|en = 'Other (any other contact details )';
																					|it = 'Altro (qualsiasi altra informazione di contatto)';
																					|pl = 'Inne (inna informacja kontaktowa)';
																					|tr = 'Diğer (başka herhangi iletişim bilgileri)'", LanguagesCodes); // @NStr-2
	Item.FieldKindOther = "MultilineWide";
	Item.EditingOption = "InputField";
	Item.IDForFormulas = "Other";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Other;

	Item = Items.Add();
	Item.PredefinedDataName = "InternationalAddressOfCompany";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCompanies;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ quốc tế để thanh toán (Anh.)';
																					|ru = 'Международный адрес для платежей (англ.)';
																					|en = 'International address for payments (eng.)';
																					|it = 'Indirizzo internazionale per i pagamenti (eng.)';
																					|pl = 'Międzynarodowy adres płatniczy (ang.)';
																					|tr = 'Uluslararası ödeme adresi (ing.)'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "InternationalAddressForPaymentsEnglish";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "CompanyPostalAddress";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCompanies;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ bưu điện';
																					|ru = 'Почтовый адрес';
																					|en = 'Postal address';
																					|it = 'Indirizzo postale';
																					|pl = 'Adres pocztowy';
																					|tr = 'Posta adresi'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "MailAddress";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "CompanyPhone";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCompanies;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại';
																					|ru = 'Телефон';
																					|en = 'Phone';
																					|it = 'Телефон';
																					|pl = 'Telefon';
																					|tr = 'Telefon'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "Phone";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "CompanyFax";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCompanies;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Fax';
																					|ru = 'Факс';
																					|en = 'Fax';
																					|it = 'Факс';
																					|pl = 'Faks';
																					|tr = 'Faks'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "Fax";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Fax;

	Item = Items.Add();
	Item.PredefinedDataName = "ActualDataAddressOfCompany";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCompanies;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ thực tế';
																					|ru = 'Фактический адрес';
																					|en = 'Business address';
																					|it = 'Sede operativa';
																					|pl = 'Adres faktyczny';
																					|tr = 'İş adresi'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "ActualAddress";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "EmailCompanies";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCompanies;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'E-mail';
																					|ru = 'Электронная почта';
																					|en = 'Email';
																					|it = 'Posta elettronica';
																					|pl = 'Poczta elektroniczna';
																					|tr = 'E-posta'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputField";
	Item.IDForFormulas = "Email";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Email;

	Item = Items.Add();
	Item.PredefinedDataName = "LegalAddressOfCompany";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogCompanies;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ đăng ký';
																					|ru = 'Юридический адрес';
																					|en = 'Legal address';
																					|it = 'Sede legale';
																					|pl = 'Adres prawny';
																					|tr = 'Yasal adres'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "LegalAddress";
	Item.Used = True;
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.OnlyNationalAddress = True;
	Item.StoreChangeHistory = True;

	Item = Items.Add();
	Item.PredefinedDataName = "PartnerAddress";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPartners;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ';
																					|ru = 'Адрес';
																					|en = 'Address';
																					|it = 'Адрес';
																					|pl = 'Adres';
																					|tr = 'Adres'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "Address";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "PartnerSPhoneNumber";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPartners;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại';
																					|ru = 'Телефон';
																					|en = 'Phone';
																					|it = 'Телефон';
																					|pl = 'Telefon';
																					|tr = 'Telefon'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "Phone";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "EmailPartner_";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPartners;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'E-mail';
																					|ru = 'Электронная почта';
																					|en = 'Email';
																					|it = 'Posta elettronica';
																					|pl = 'Poczta elektroniczna';
																					|tr = 'E-posta'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputField";
	Item.IDForFormulas = "Email";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Email;

	Item = Items.Add();
	Item.PredefinedDataName = "TaxAuthorityAddress";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogRegistrationsInTaxAuthority;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ cơ quan thuế';
																					|ru = 'Адрес налогового органа';
																					|en = 'Tax authority address';
																					|it = 'Indirizzo dell''autorità fiscale';
																					|pl = 'Adres urzędu skarbowego';
																					|tr = 'Vergi dairesi adresi'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "TaxAuthorityAddress";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "TaxAuthorityPhone";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogRegistrationsInTaxAuthority;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại của cơ quan thuế';
																					|ru = 'Телефон налогового органа';
																					|en = 'Tax authority phone';
																					|it = 'Telefono dell''autortià fiscale';
																					|pl = 'Telefon urzędu skarbowego';
																					|tr = 'Vergi dairesi telefonu'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "TaxAuthorityPhone";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "ActualAddressOfBranchOffice";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogRegistrationsInTaxAuthority;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ thực tế của đơn vị độc lập';
																					|ru = 'Фактический адрес обособленного подразделения';
																					|en = 'Branch office business address';
																					|it = 'Indirizzo effettivo del reparto esterno';
																					|pl = 'Aktualny adres oddzielnego działu';
																					|tr = 'Ayrı departmanın iş adresi'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "BusinessAddressOfSeparateDivision";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "WarehouseAddress";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogWarehouses;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ kho';
																					|ru = 'Адрес склада';
																					|en = 'Warehouse address';
																					|it = 'Indirizzo magazzino';
																					|pl = 'Adres magazynu';
																					|tr = 'Ambar adresi'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "WarehouseAddress";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "WarehousePhone";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogWarehouses;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại kho';
																					|ru = 'Телефон склада';
																					|en = 'Warehouse phone';
																					|it = 'Telefono magazzino';
																					|pl = 'Telefon magazynu';
																					|tr = 'Ambar telefonu'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "WarehousePhone";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "AddressForInformingPersons";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPersons;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ để thông tin hóa';
																					|ru = 'Адрес для информирования';
																					|en = 'Notice address';
																					|it = 'Indirizzo per informazioni';
																					|pl = 'Adres do informowania';
																					|tr = 'Bilgilendirme adresi'", LanguagesCodes); // @NStr-2
	Item.IncludeCountryInPresentation = True;
	Item.EditingOption = "Dialog";
	Item.IDForFormulas = "AddressForInformation";
	Item.PredefinedKindName = "AddressForInformingPersons";
	Item.Used = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "ResidentialAddressPersons";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPersons;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ cư trú';
																					|ru = 'Адрес места проживания';
																					|en = 'Residential address';
																					|it = 'Indirizzo di residenza';
																					|pl = 'Adres miejsca zamieszkania';
																					|tr = 'Yerleşim yeri'", LanguagesCodes); // @NStr-2
	Item.IncludeCountryInPresentation = True;
	Item.EditingOption = "Dialog";
	Item.IDForFormulas = "AddressOfPlaceOfResidence";
	Item.PredefinedKindName = "ResidentialAddressPersons";
	Item.Used = True;
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.OnlyNationalAddress = True;

	Item = Items.Add();
	Item.PredefinedDataName = "RegistrationAddressPersons";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPersons;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ đăng ký';
																					|ru = 'Адрес по прописке';
																					|en = 'Registration address';
																					|it = 'Indirizzo di registrazione';
																					|pl = 'Adres zameldowania';
																					|tr = 'İkametgah'", LanguagesCodes); // @NStr-2
	Item.IncludeCountryInPresentation = True;
	Item.EditingOption = "Dialog";
	Item.IDForFormulas = "RegisteredAddress";
	Item.PredefinedKindName = "RegistrationAddressPersons";
	Item.Used = True;
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.OnlyNationalAddress = True;

	Item = Items.Add();
	Item.PredefinedDataName = "HomePhoneNumberOfPerson";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPersons;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại nhà riêng';
																					|ru = 'Домашний телефон';
																					|en = 'Home phone';
																					|it = 'Telefono (casa)';
																					|pl = 'Telefon domowy';
																					|tr = 'Ev telefonu'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "HomePhone_Number";
	Item.PredefinedKindName = "HomePhoneNumberOfPerson";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "AddressOutsideRussianFederationPersons";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPersons;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Địa chỉ nước ngoài';
																					|ru = 'Иностранный адрес';
																					|en = 'Foreign address';
																					|it = 'Indirizzo straniero';
																					|pl = 'Adres zagraniczny';
																					|tr = 'Yabancı adres'", LanguagesCodes); // @NStr-2
	Item.IncludeCountryInPresentation = True;
	Item.EditingOption = "Dialog";
	Item.IDForFormulas = "ForeignAddress";
	Item.PredefinedKindName = "AddressOutsideRussianFederationPersons";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.Type = Enums.ContactInformationTypes.Address;

	Item = Items.Add();
	Item.PredefinedDataName = "MobilePhoneOfPerson";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPersons;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại di động';
																					|ru = 'Мобильный телефон';
																					|en = 'Cell phone';
																					|it = 'Numero di telefono cellulare';
																					|pl = 'Telefon komórkowy';
																					|tr = 'Cep telefonu'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "MobilePhone";
	Item.PredefinedKindName = "MobilePhoneOfPerson";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "WorkingPhoneNumberOfPerson";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPersons;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Điện thoại công việc';
																					|ru = 'Рабочий телефон';
																					|en = 'Work phone';
																					|it = 'Numero di telefono dell''ufficio';
																					|pl = 'Telefon miejsca pracy';
																					|tr = 'İş telefonu'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputFieldAndDialog";
	Item.IDForFormulas = "BusinessPhoneNumber";
	Item.PredefinedKindName = "WorkingPhoneNumberOfPerson";
	Item.Used = True;
	Item.AllowMultipleValueInput = True;
	Item.PhoneWithExtensionNumber = True;
	Item.Type = Enums.ContactInformationTypes.Phone;

	Item = Items.Add();
	Item.PredefinedDataName = "EMailPersons";
	Item.Parent = Catalogs.ContactInformationKinds.CatalogPersons;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'E-mail';
																					|ru = 'Электронная почта';
																					|en = 'Email';
																					|it = 'Posta elettronica';
																					|pl = 'Poczta elektroniczna';
																					|tr = 'E-posta'", LanguagesCodes); // @NStr-2
	Item.EditingOption = "InputField";
	Item.IDForFormulas = "Email";
	Item.PredefinedKindName = "EMailPersons";
	Item.Used = True;
	Item.CheckValidity = True;
	Item.Type = Enums.ContactInformationTypes.Email;

	
EndProcedure

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles - Object to populate.
//  Data                  - ValueTableRow - Object fill data.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable - Data populated in the OnInitialItemsFilling procedure.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

#EndRegion
