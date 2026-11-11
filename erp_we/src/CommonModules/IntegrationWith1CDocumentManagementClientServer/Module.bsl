////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Integration module 1sdocumentclientserver: client, server
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a Presentation of the Document Flow object type XDTO by type name.
// By default, it returns a singular Presentation.
//
// Parameters:
//   XDTOType - String - the name of the XDTO object type.
//   PluralForm - Boolean - It is required to return the Presentation in the plural.
//   ForFormOfSelection - Boolean - it is required to return a Presentation for the selection Form starting with "Selection ...".
//
// Returns:
//   String - representation of the type of the Document Flow object XDTO by type name.
//
Function ObjectTypePresentationXDTO(XDTOType, PluralForm = False, ForFormOfSelection = False) Export
	
	SingularForm = Not PluralForm And Not ForFormOfSelection;
	
	TypesPresentation1 = New Map;
	
	// Reference books.
	If SingularForm Then
		Presentation = NStr("vi = 'Đối tác, Doanh nghiệp, Người sử dụng';
							|ru = 'Контрагент, Организация, Пользователь';
							|en = 'Counterparty, Company, User'; fa = 'Counterparty, Company, User';
							|it = 'Controparte, Azienda, Utente';
							|pl = 'Kontrahent, Firma, Użytkownik';
							|tr = 'Cari hesap, İş yeri, Kullanıcı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn bên';
							|ru = 'Выбор стороны';
							|en = 'Select a party'; fa = 'Select a party';
							|it = 'Selezione della parte';
							|pl = 'Wybór strony';
							|tr = 'Taraf seçimi'");
	Else
		Presentation = NStr("vi = 'Đối tác, Doanh nghiệp, Người sử dụng';
							|ru = 'Контрагенты, Организации, Пользователи';
							|en = 'Counterparties, Companies, Users'; fa = 'Counterparties, Companies, Users';
							|it = 'Controparti, Aziende, Utenti';
							|pl = 'Kontrahenci, Firmy, Użytkownicy';
							|tr = 'Cari hesaplar, İş yerleri, Kullanıcılar'");
	EndIf;
	TypesPresentation1.Insert("DMParty", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dự án';
							|ru = 'Проект';
							|en = 'Project'; fa = 'پروژه';
							|it = 'Progetto';
							|pl = 'Projekt';
							|tr = 'Proje'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dự án';
							|ru = 'Выбор проекта';
							|en = 'Select project '; fa = 'Select project ';
							|it = 'Selezione del progetto';
							|pl = 'Wybór projektu';
							|tr = 'Proje seçimi'");
	Else
		Presentation = NStr("vi = 'Dự án';
							|ru = 'Проекты';
							|en = 'Projects'; fa = 'پروژه‌ها';
							|it = 'Progetti';
							|pl = 'Projekty';
							|tr = 'Projeler'");
	EndIf;
	TypesPresentation1.Insert("DMProject", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Nhiệm vụ dự án';
							|ru = 'Проектная задача';
							|en = 'Project task'; fa = 'وظیفه پروژه';
							|it = 'Compito del progetto';
							|pl = 'Zadanie projektowe';
							|tr = 'Proje görevi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn nhiệm vụ dự án';
							|ru = 'Выбор проектной задачи';
							|en = 'Select project task'; fa = 'Select project task';
							|it = 'Selezione del compito di progetto';
							|pl = 'Wybór zadania projektowego';
							|tr = 'Proje görevi seçimi'");
	Else
		Presentation = NStr("vi = 'Nhiệm vụ dự án';
							|ru = 'Проектные задачи';
							|en = 'Project tasks'; fa = 'وظایف پروژه';
							|it = 'Compiti del progetto';
							|pl = 'Zadania projektowe';
							|tr = 'Proje görevleri'");
	EndIf;
	TypesPresentation1.Insert("DMProjectTask", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Cuộc họp';
							|ru = 'Мероприятие';
							|en = 'Activity'; fa = 'فعالیت';
							|it = 'Evento';
							|pl = 'Przedsięwzięcie';
							|tr = 'Etkinlik'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn cuộc họp';
							|ru = 'Выбор мероприятия';
							|en = 'Select an activity'; fa = 'Select an activity';
							|it = 'Scelta evento';
							|pl = 'Wybór wydarzenia';
							|tr = 'Etkinlik seçimi'");
	Else
		Presentation = NStr("vi = 'Cuộc họp';
							|ru = 'Мероприятия';
							|en = 'Activities'; fa = 'Activities';
							|it = 'Eventi';
							|pl = 'Wydarzenia';
							|tr = 'Etkinlik'");
	EndIf;
	TypesPresentation1.Insert("DMMeeting", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Chủ đề thảo luận';
							|ru = 'Тема обсуждения';
							|en = 'Discussion topic'; fa = 'Discussion topic';
							|it = 'Argomento di discussione';
							|pl = 'Temat dyskusji';
							|tr = 'Tartışma konusu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn chủ đề thảo luận';
							|ru = 'Выбор темы обсуждений';
							|en = 'Select a discussion topic'; fa = 'Select a discussion topic';
							|it = 'Selezionare l''argomento di discussione';
							|pl = 'Wybór tematu dyskusji';
							|tr = 'Tartışma konusu seçimi'");
	Else
		Presentation = NStr("vi = 'Chủ đề thảo luận';
							|ru = 'Темы обсуждений';
							|en = 'Discussion topics'; fa = 'Discussion topics';
							|it = 'Argomenti di discussione';
							|pl = 'Tematy dyskusji';
							|tr = 'Tartışma konuları'");
	EndIf;
	TypesPresentation1.Insert("DMDiscussionTopic", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thông báo thảo luận';
							|ru = 'Сообщение обсуждения';
							|en = 'Discussion message'; fa = 'Discussion message';
							|it = 'Messaggio discussione';
							|pl = 'Wiadomość dyskusji';
							|tr = 'Tartışma mesajı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thông báo thảo luận';
							|ru = 'Выбор сообщения обсуждений';
							|en = 'Select a discussion message'; fa = 'Select a discussion message';
							|it = 'Selezionare messaggio di discussioni';
							|pl = 'Wybór wiadomości dyskusji';
							|tr = 'Tartışma mesajı seçimi'");
	Else
		Presentation = NStr("vi = 'Thông báo thảo luận';
							|ru = 'Сообщения обсуждений';
							|en = 'Discussion messages'; fa = 'Discussion messages';
							|it = 'Messaggi discussioni';
							|pl = 'Wiadomości dyskusji';
							|tr = 'Tartışma mesajı'");
	EndIf;
	TypesPresentation1.Insert("DMDiscussionMessage", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Tệp';
							|ru = 'Файл';
							|en = 'File'; fa = 'فایل';
							|it = 'File';
							|pl = 'Plik';
							|tr = 'Dosya'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn tệp';
							|ru = 'Выбор файла';
							|en = 'Select file'; fa = 'انتخاب فایل';
							|it = 'Selezione del file';
							|pl = 'Wybór pliku';
							|tr = 'Dosya seçimi'");
	Else
		Presentation = NStr("vi = 'Tệp';
							|ru = 'Файлы';
							|en = 'Files'; fa = 'فایل‌ها';
							|it = 'File';
							|pl = 'Pliki';
							|tr = 'Dosyalar'");
	EndIf;
	TypesPresentation1.Insert("DMFile", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thư mục tệp';
							|ru = 'Папка файлов';
							|en = 'File folder'; fa = 'پوشه فایل';
							|it = 'Cartella di file';
							|pl = 'Folder plików';
							|tr = 'Dosya klasörleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thư mục tệp';
							|ru = 'Выбор папки файлов';
							|en = 'Select file folder'; fa = 'Select file folder';
							|it = 'Selezione cartella file';
							|pl = 'Wybór folderu plików';
							|tr = 'Dosya klasörleri seçimi'");
	Else
		Presentation = NStr("vi = 'Thư mục tệp';
							|ru = 'Папки файлов';
							|en = 'File folders'; fa = 'پوشه‌های فایل';
							|it = 'Cartelle di file';
							|pl = 'Fołdery plików';
							|tr = 'Dosya klasörleri'");
	EndIf;
	TypesPresentation1.Insert("DMFileFolder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Папка внутренних документов';
							|vi = 'Folder of internal documents';
							|en = 'Folder of internal documents'; fa = 'پوشه اسناد داخلی';
							|it = 'Cartella documenti interni';
							|pl = 'Folder dokumentów wewnętrznych';
							|tr = 'Dahili belgeler klasörü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор папки внутренних документов';
							|vi = 'Select an internal documents folder';
							|en = 'Select an internal documents folder'; fa = 'Select an internal documents folder';
							|it = 'Select an internal documents folder';
							|pl = 'Select an internal documents folder';
							|tr = 'Dahili belgeler klasörü seçimi'");
	Else
		Presentation = NStr("ru = 'Папки внутренних документов';
							|vi = 'Internal document folders';
							|en = 'Internal document folders'; fa = 'Internal document folders';
							|it = 'Cartelle dei documenti interni';
							|pl = 'Foldery dokumentów wewnętrznych';
							|tr = 'Dahili belgeler klasörleri'");
	EndIf;
	TypesPresentation1.Insert("DMInternalDocumentFolder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thư mục cuộc họp.';
							|ru = 'Папка мероприятий';
							|en = 'Event folder'; fa = 'Event folder';
							|it = 'Cartella eventi';
							|pl = 'Folder wydarzeń';
							|tr = 'Etkinlikleri klasörü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thư mục cuộc họp';
							|ru = 'Выбор папки мероприятий';
							|en = 'Select an event folder'; fa = 'Select an event folder';
							|it = 'Scelta della cartella eventi';
							|pl = 'Wybór folderu wydarzeń';
							|tr = 'Etkinlikleri klasörü seçimi'");
	Else
		Presentation = NStr("vi = 'Thư mục cuộc họp';
							|ru = 'Папки мероприятий';
							|en = 'Event folders'; fa = 'Event folders';
							|it = 'Cartelle eventi';
							|pl = 'Foldery wydarzeń';
							|tr = 'Etkinliklerin klasörleri'");
	EndIf;
	TypesPresentation1.Insert("DMMeetingFolder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Người sử dụng';
							|ru = 'Пользователь';
							|en = 'User'; fa = 'کاربر';
							|it = 'Utente';
							|pl = 'Użytkownik';
							|tr = 'Kullanıcı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn người sử dụng';
							|ru = 'Выбор пользователя';
							|en = 'Select user'; fa = 'انتخاب کاربر';
							|it = 'Scelta di un utente';
							|pl = 'Wybór użytkownika';
							|tr = 'Kullanıcı seçimi'");
	Else
		Presentation = NStr("vi = 'Người sử dụng';
							|ru = 'Пользователи';
							|en = 'Users'; fa = 'کاربران';
							|it = 'Utenti';
							|pl = 'Użytkownicy';
							|tr = 'Kullanıcılar'");
	EndIf;
	TypesPresentation1.Insert("DMUser", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Nhóm người sử dụng';
							|ru = 'Группа пользователей';
							|en = 'User group'; fa = 'گروه کاربران';
							|it = 'Gruppo di utenti';
							|pl = 'Grupa użytkowników';
							|tr = 'Kullanıcı grubu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn nhóm người sử dụng';
							|ru = 'Выбор группы пользователей';
							|en = 'Select user group'; fa = 'انتخاب گروه کاربری';
							|it = 'Selezione del gruppo di utenti';
							|pl = 'Wybór grupy użytkowników';
							|tr = 'Kullanıcı grubunu seçin'");
	Else
		Presentation = NStr("vi = 'Nhóm người sử dụng';
							|ru = 'Группы пользователей';
							|en = 'User groups'; fa = 'گروه‌های کاربران';
							|it = 'Gruppi di utenti';
							|pl = 'Grupy użytkowników';
							|tr = 'Kullanıcı grupları'");
	EndIf;
	TypesPresentation1.Insert("DMUserGroup", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Vấn đề nghiệp vụ';
							|ru = 'Вопрос деятельности';
							|en = 'Activity issue'; fa = 'موضوع فعالیت';
							|it = 'Problema di attività';
							|pl = 'Kwestia działalności';
							|tr = 'Faaliyet sorusu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn lĩnh vực hoạt động';
							|ru = 'Выбор вопроса деятельности';
							|en = 'Select activity issue'; fa = 'Select activity issue';
							|it = 'Selezione problema di attività';
							|pl = 'Wybór kwestii działalności';
							|tr = 'Faaliyet sorusu seçimi'");
	Else
		Presentation = NStr("vi = 'Vấn đề nghiệp vụ';
							|ru = 'Вопросы деятельности';
							|en = 'Activity issues'; fa = 'Activity issues';
							|it = 'Problemi di attività';
							|pl = 'Kwestie działalności';
							|tr = 'Faaliyet soruları'");
	EndIf;
	TypesPresentation1.Insert("DMActivityMatter", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Tiền tệ';
							|ru = 'Валюта';
							|en = 'Currency'; fa = 'ارز';
							|it = 'Valuta';
							|pl = 'Waluta';
							|tr = 'Para birimi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn tiền tệ';
							|ru = 'Выбор валюты';
							|en = 'Select currency '; fa = 'Select currency ';
							|it = 'Selezione valuta';
							|pl = 'Wybór waluty';
							|tr = 'Para birimi seçimi'");
	Else
		Presentation = NStr("vi = 'Tiền tệ';
							|ru = 'Валюты';
							|en = 'Currencies'; fa = 'ارزها';
							|it = 'Valute';
							|pl = 'Waluty';
							|tr = 'Para birimleri'");
	EndIf;
	TypesPresentation1.Insert("DMCurrency", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Внутренний документ';
							|vi = 'Internal document';
							|en = 'Internal document'; fa = 'سند داخلی';
							|it = 'Documento interno';
							|pl = 'Dokument wewnętrzny';
							|tr = 'Dahili transfer belgesi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор внутреннего документа';
							|vi = 'Select internal document';
							|en = 'Select internal document'; fa = 'انتخاب سند داخلی';
							|it = 'Selezione documento interno';
							|pl = 'Wybór dokumentu wewnętrznego';
							|tr = 'Dahili transfer belgeleri seçimi'");
	Else
		Presentation = NStr("ru = 'Внутренние документы';
							|vi = 'Internal documents';
							|en = 'Internal documents'; fa = 'اسناد داخلی';
							|it = 'Documenti interni';
							|pl = 'Dokumenty wewnętrzne';
							|tr = 'Dahili belgeler'");
	EndIf;
	TypesPresentation1.Insert("DMInternalDocument", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Входящий документ';
							|vi = 'Incoming document';
							|en = 'Incoming document'; fa = 'سند ورودی';
							|it = 'Documento in entrata';
							|pl = 'Dokument przychodzący';
							|tr = 'Gelen belge'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор входящего документа';
							|vi = 'Select incoming document';
							|en = 'Select incoming document'; fa = 'Select incoming document';
							|it = 'Selezione documento in entrata';
							|pl = 'Wybór dokumentu wchodzącego';
							|tr = 'Gelen belge seçimi'");
	Else
		Presentation = NStr("ru = 'Входящие документы';
							|vi = 'Incoming documents';
							|en = 'Incoming documents'; fa = 'اسناد ورودی';
							|it = 'Documenti in entrata';
							|pl = 'Dokumenty przychodzące';
							|tr = 'Gelen belge'");
	EndIf;
	TypesPresentation1.Insert("DMIncomingDocument", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Исходящий документ';
							|vi = 'Outgoing document';
							|en = 'Outgoing document'; fa = 'سند خروجی';
							|it = 'Documento in uscita';
							|pl = 'Dokument wychodzący';
							|tr = 'Giden belge'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор исходящего документа';
							|vi = 'Select outgoing document';
							|en = 'Select outgoing document'; fa = 'Select outgoing document';
							|it = 'Selezione documento in uscita';
							|pl = 'Wybór dokumentu wychodzącego';
							|tr = 'Giden belge seçimi'");
	Else
		Presentation = NStr("ru = 'Исходящие документы';
							|vi = 'Outgoing documents';
							|en = 'Outgoing documents'; fa = 'Outgoing documents';
							|it = 'Documenti in uscita';
							|pl = 'Dokumenty wychodzące';
							|tr = 'Giden belgeler'");
	EndIf;
	TypesPresentation1.Insert("DMOutgoingDocument", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Doanh nghiệp';
							|ru = 'Организация';
							|en = 'Company'; fa = 'Company';
							|it = 'Azienda';
							|pl = 'Firma';
							|tr = 'İş yeri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn doanh nghiệp';
							|ru = 'Выбор организации';
							|en = 'Select company'; fa = 'Select company';
							|it = 'Selezione azienda';
							|pl = 'Wybór firmy';
							|tr = 'İş yeri seçimi'");
	Else
		Presentation = NStr("vi = 'Doanh nghiệp';
							|ru = 'Организации';
							|en = 'Companies'; fa = 'شرکت‌ها';
							|it = 'Aziende';
							|pl = 'Organizacje';
							|tr = 'İş yerleri'");
	EndIf;
	TypesPresentation1.Insert("DMOrganization", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Đối tác';
							|ru = 'Контрагент';
							|en = 'Counterparty'; fa = 'طرف حساب';
							|it = 'Controparte';
							|pl = 'Kontrahent';
							|tr = 'Cari hesap'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn đối tác';
							|ru = 'Выбор контрагента';
							|en = 'Select a counterparty'; fa = 'Select a counterparty';
							|it = 'Selezione controparte';
							|pl = 'Wybór kontrahenta';
							|tr = 'Cari hesap seçimi'");
	Else
		Presentation = NStr("vi = 'Đối tác';
							|ru = 'Контрагенты';
							|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
							|it = 'Controparti';
							|pl = 'Kontrahenci';
							|tr = 'Cari hesaplar'");
	EndIf;
	TypesPresentation1.Insert("DMCorrespondent", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Người liên hệ';
							|ru = 'Контактное лицо';
							|en = 'Contact person'; fa = 'شخص تماس';
							|it = 'Contatto';
							|pl = 'Osoba do kontaktu';
							|tr = 'İrtibat kişisi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn người liên hệ';
							|ru = 'Выбор контактного лица';
							|en = 'Select contact person'; fa = 'Select contact person';
							|it = 'Selezione contatto';
							|pl = 'Wybór osoby kontaktowej';
							|tr = 'İlgili kişi seçimi'");
	Else
		Presentation = NStr("vi = 'Người liên hệ';
							|ru = 'Контактные лица';
							|en = 'Contact persons'; fa = 'اشخاص تماس';
							|it = 'Persone di contatto';
							|pl = 'Osoby kontaktowe';
							|tr = 'İlgili kişiler'");
	EndIf;
	TypesPresentation1.Insert("DMContactPerson", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Độ mật';
							|ru = 'Гриф доступа';
							|en = 'Access label'; fa = 'برچسب دسترسی';
							|it = 'Dicitura di accesso';
							|pl = 'Poziom dostępu';
							|tr = 'Erişim etiketi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn độ mật';
							|ru = 'Выбор грифа доступа';
							|en = 'Select access label'; fa = 'Select access label';
							|it = 'Selezione dicitura di accesso';
							|pl = 'Wybór poziomu dostępu';
							|tr = 'Erişim etiketi seçimi'");
	Else
		Presentation = NStr("vi = 'Độ mật';
							|ru = 'Грифы доступа';
							|en = 'Access labels'; fa = 'Access labels';
							|it = 'Diciture di accesso';
							|pl = 'Poziomy dostępu';
							|tr = 'Erişim etiketleri'");
	EndIf;
	TypesPresentation1.Insert("DMAccessLevel", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Phương thức truyền';
							|ru = 'Способ доставки';
							|en = 'Delivery method'; fa = 'روش تحویل';
							|it = 'Metodo di consegna';
							|pl = 'Sposób dostarczenia';
							|tr = 'Teslimat yöntemi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn phương thức truyền';
							|ru = 'Выбор способа доставки';
							|en = 'Select delivery method'; fa = 'Select delivery method';
							|it = 'Selezione metodo di consegna';
							|pl = 'Wybór sposobu dostawy';
							|tr = 'Teslimat yöntemi seçimi'");
	Else
		Presentation = NStr("vi = 'Phương thức truyền';
							|ru = 'Способы доставки';
							|en = 'Delivery methods'; fa = 'روش‌های تحویل';
							|it = 'Metodi di consegna';
							|pl = 'Sposoby dostawy';
							|tr = 'Teslimat yöntemleri'");
	EndIf;
	TypesPresentation1.Insert("DMDeliveryMethod", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Bộ phận';
							|ru = 'Подразделение';
							|en = 'Business unit'; fa = 'Business unit';
							|it = 'Reparto';
							|pl = 'Dział';
							|tr = 'Departman'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn bộ phận';
							|ru = 'Выбор подразделения';
							|en = 'Select business unit'; fa = 'Select business unit';
							|it = 'Selezione del reparto';
							|pl = 'Wybór działu';
							|tr = 'Departman seçimi'");
	Else
		Presentation = NStr("vi = 'Bộ phận';
							|ru = 'Подразделения';
							|en = 'Business units'; fa = 'واحدهای تجاری';
							|it = 'Reparti';
							|pl = 'Działy';
							|tr = 'Departman'");
	EndIf;
	TypesPresentation1.Insert("DMSubdivision", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Вид внутреннего документа';
							|vi = 'Internal document kind';
							|en = 'Internal document kind'; fa = 'Internal document kind';
							|it = 'Internal document kind';
							|pl = 'Internal document kind';
							|tr = 'Dahili belge türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор вида внутренних документов';
							|vi = 'Select an internal document kind';
							|en = 'Select an internal document kind'; fa = 'Select an internal document kind';
							|it = 'Select an internal document kind';
							|pl = 'Select an internal document kind';
							|tr = 'Dahili belge türü seçimi'");
	Else
		Presentation = NStr("ru = 'Виды внутренних документов';
							|vi = 'Kinds of internal documents';
							|en = 'Kinds of internal documents'; fa = 'Kinds of internal documents';
							|it = 'Tipi di documenti interni';
							|pl = 'Rodzaje dokumentów wewnętrznych';
							|tr = 'Dahili belgeler türleri'");
	EndIf;
	TypesPresentation1.Insert("DMInternalDocumentType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Вид входящего документа';
							|vi = 'Incoming document kind';
							|en = 'Incoming document kind'; fa = 'Incoming document kind';
							|it = 'Incoming document kind';
							|pl = 'Incoming document kind';
							|tr = 'Gelen belge türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор вида входящих документов';
							|vi = 'Select an incoming document kind';
							|en = 'Select an incoming document kind'; fa = 'Select an incoming document kind';
							|it = 'Select an incoming document kind';
							|pl = 'Select an incoming document kind';
							|tr = 'Gelen belge türü seçimi'");
	Else
		Presentation = NStr("ru = 'Виды входящих документов';
							|vi = 'Kinds of incoming documents';
							|en = 'Kinds of incoming documents'; fa = 'Kinds of incoming documents';
							|it = 'Tipi di documenti in entrata';
							|pl = 'Rodzaje dokumentów przychodzących';
							|tr = 'Gelen belge türleri'");
	EndIf;
	TypesPresentation1.Insert("DMIncomingDocumentType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Вид исходящего документа';
							|vi = 'Outgoing document kind';
							|en = 'Outgoing document kind'; fa = 'Outgoing document kind';
							|it = 'Outgoing document kind';
							|pl = 'Outgoing document kind';
							|tr = 'Giden belge türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор вида исходящих документов';
							|vi = 'Select an outgoing document kind';
							|en = 'Select an outgoing document kind'; fa = 'Select an outgoing document kind';
							|it = 'Select an outgoing document kind';
							|pl = 'Select an outgoing document kind';
							|tr = 'Giden belge türü seçimi'");
	Else
		Presentation = NStr("ru = 'Виды исходящих документов';
							|vi = 'Kinds of outgoing documents';
							|en = 'Kinds of outgoing documents'; fa = 'Kinds of outgoing documents';
							|it = 'Tipi di documenti in uscita';
							|pl = 'Rodzaje dokumentów wychodzących';
							|tr = 'Giden belge türleri'");
	EndIf;
	TypesPresentation1.Insert("DMOutgoingDocumentType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng cuộc họp';
							|ru = 'Вид мероприятия';
							|en = 'Event type'; fa = 'نوع رویداد';
							|it = 'Tipo di evento';
							|pl = 'Rodzaj wydarzenia';
							|tr = 'Etkinlik türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng cuộc họp';
							|ru = 'Выбор вида мероприятия';
							|en = 'Select an event type'; fa = 'Select an event type';
							|it = 'Selezione del tipo di evento';
							|pl = 'Wybór rodzaju wydarzenia';
							|tr = 'Etkinlik türü seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng cuộc họp';
							|ru = 'Виды мероприятий';
							|en = 'Event types'; fa = 'Event types';
							|it = 'Tipi di eventi';
							|pl = 'Rodzaje wydarzeń';
							|tr = 'Etkinlik türleri'");
	EndIf;
	TypesPresentation1.Insert("DMMeetingType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng công việc';
							|ru = 'Вид работ';
							|en = 'Activity kind'; fa = 'نوع فعالیت';
							|it = 'Tipo di lavori';
							|pl = 'Rodzaj prac';
							|tr = 'İş türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng công việc';
							|ru = 'Выбор вида работ';
							|en = 'Select activity kind'; fa = 'Select activity kind';
							|it = 'Selezione del tipo di lavori';
							|pl = 'Wybór rodzaju prac';
							|tr = 'İş türü seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng công việc';
							|ru = 'Виды работ';
							|en = 'Activity kinds'; fa = 'انواع فعالیت';
							|it = 'Tipi di lavori';
							|pl = 'Rodzaje prac';
							|tr = 'İş türleri'");
	EndIf;
	TypesPresentation1.Insert("DMWorkType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Kiểu liên kết';
							|ru = 'Тип связей';
							|en = 'Link type'; fa = 'نوع پیوند';
							|it = 'Tipo di connessioni';
							|pl = 'Typ powiązań';
							|tr = 'Bağlantı türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn kiểu liên kết';
							|ru = 'Выбор типа связей';
							|en = 'Select a link type'; fa = 'Select a link type';
							|it = 'Selezione del tipo di connessioni';
							|pl = 'Wybór typu powiązań';
							|tr = 'Bağlantı türü seçimi'");
	Else
		Presentation = NStr("vi = 'Kiểu liên kết';
							|ru = 'Типы связей';
							|en = 'Link types'; fa = 'انواع پیوند';
							|it = 'Tipi di connessioni';
							|pl = 'Typy powiązań';
							|tr = 'Bağlantı türleri'");
	EndIf;
	TypesPresentation1.Insert("DMRelationType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Giá trị thuộc tính đối tượng';
							|ru = 'Значение свойств объектов';
							|en = 'Object property value'; fa = 'Object property value';
							|it = 'Valori delle proprietà degli oggetti';
							|pl = 'Wartość właściwości obiektów';
							|tr = 'Nesnelerin özellik değerleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn giá trị thuộc tính đối tượng';
							|ru = 'Выбор значения свойств объектов';
							|en = 'Select an object property value'; fa = 'Select an object property value';
							|it = 'Scelta valori delle proprietà degli oggetti';
							|pl = 'Wybór wartości właściwości obiektów';
							|tr = 'Nesnelerin özellik değeri seçimi'");
	Else
		Presentation = NStr("vi = 'Giá trị thuộc tính đối tượng';
							|ru = 'Значения свойств объектов';
							|en = 'Object property values'; fa = 'Object property values';
							|it = 'Valori delle proprietà degli oggetti';
							|pl = 'Wartości właściwości obiektów';
							|tr = 'Nesnelerin özellik değeri'");
	EndIf;
	TypesPresentation1.Insert("DMObjectPropertyValue", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Cá nhân';
							|ru = 'Физическое лицо';
							|en = 'Person'; fa = 'شخص';
							|it = 'Persona fisica';
							|pl = 'Osoba fizyczna';
							|tr = 'Gerçek kişi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn cá nhân';
							|ru = 'Выбор физического лица';
							|en = 'Select person'; fa = 'Select person';
							|it = 'Selezione persona fisica';
							|pl = 'Wybór osoby fizycznej';
							|tr = 'Gerçek kişi seçimi'");
	Else
		Presentation = NStr("vi = 'Cá nhân';
							|ru = 'Физические лица';
							|en = 'Persons'; fa = 'اشخاص';
							|it = 'Persone fisiche';
							|pl = 'Osoby fizyczne';
							|tr = 'Gerçek kişiler'");
	EndIf;
	TypesPresentation1.Insert("DMPrivatePerson", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Điều kiện lộ trình hóa';
							|ru = 'Условие маршрутизации';
							|en = 'Routing condition'; fa = 'Routing condition';
							|it = 'Condizioni di routing';
							|pl = 'Warunek trasowania';
							|tr = 'Yönlendirme koşulu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn điều kiện lộ trình hóa';
							|ru = 'Выбор условия маршрутизации';
							|en = 'Select a routing condition'; fa = 'Select a routing condition';
							|it = 'Scelta condizioni di routing';
							|pl = 'Wybór warunku trasowania';
							|tr = 'Yönlendirme koşulunun seçimi'");
	Else
		Presentation = NStr("vi = 'Điều kiện lộ trình hóa';
							|ru = 'Условия маршрутизации';
							|en = 'Routing conditions'; fa = 'Routing conditions';
							|it = 'Condizioni di routing';
							|pl = 'Warunki trasowania';
							|tr = 'Yönlendirme koşulu'");
	EndIf;
	TypesPresentation1.Insert("DMRoutingCondition", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Cá nhân nhận:';
							|ru = 'Личный адресат';
							|en = 'Personal addressee'; fa = 'Personal addressee';
							|it = 'Destinatario personale';
							|pl = 'Adresat osobisty';
							|tr = 'Kişisel alıcı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn cá nhân nhận';
							|ru = 'Выбор личного адресата';
							|en = 'Select a personal addressee'; fa = 'Select a personal addressee';
							|it = 'Scelta destinatario personale';
							|pl = 'Wybór adresatu osobistego';
							|tr = 'Kişisel alıcı seçimi'");
	Else
		Presentation = NStr("vi = 'Cá nhân nhận';
							|ru = 'Личные адресаты';
							|en = 'Personal addressees'; fa = 'مخاطبان شخصی';
							|it = 'Destinatari personali';
							|pl = 'Adresaci osobiste';
							|tr = 'Kişisel alıcılar'");
	EndIf;
	TypesPresentation1.Insert("DMPersonalRecipient", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Nhóm cá nhân nhận';
							|ru = 'Группа личных адресатов';
							|en = 'Personal addressees group'; fa = 'Personal addressees group';
							|it = 'Gruppo di destinatari personali';
							|pl = 'Grupa adresatów osobistych';
							|tr = 'Kişisel alıcılar grubu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn nhóm cá nhân nhận';
							|ru = 'Выбор группы личных адресатов';
							|en = 'Select personal addressees group'; fa = 'Select personal addressees group';
							|it = 'Scelta gruppo di destinatari personali';
							|pl = 'Wybór grupy adresatów osobistych';
							|tr = 'Kişisel alıcılar grubu seçimi'");
	Else
		Presentation = NStr("vi = 'Nhóm cá nhân nhận';
							|ru = 'Группы личных адресатов';
							|en = 'Personal addressee groups'; fa = 'Personal addressee groups';
							|it = 'Gruppi dei destinatari personali';
							|pl = 'Grupy adresatów osobistych';
							|tr = 'Kişisel alıcı grupları'");
	EndIf;
	TypesPresentation1.Insert("DMPersonalRecipientGroup", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Vai trò người thực hiện';
							|ru = 'Роль исполнителя';
							|en = 'Business role'; fa = 'نقش کسب‌وکار';
							|it = 'Ruolo dell''esecutore';
							|pl = 'Rola wykonawcy';
							|tr = 'Atanan rolü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn vai trò người thực hiện';
							|ru = 'Выбор роли исполнителей';
							|en = 'Select a business role'; fa = 'Select a business role';
							|it = 'Scelta del ruolo degli esecutori';
							|pl = 'Wybór roli wykonawcy';
							|tr = 'Yürütücü rolü seçimi'");
	Else
		Presentation = NStr("vi = 'Vai trò người thực hiện';
							|ru = 'Роли исполнителей';
							|en = 'Assignee roles'; fa = 'Assignee roles';
							|it = 'Ruoli degli esecutori';
							|pl = 'Role wykonawców';
							|tr = 'Yürütücülerin rolleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessExecutorRole", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng lưu chuyển tiền tệ';
							|ru = 'Статья движения денежных средств';
							|en = 'Cash flow item'; fa = 'قلم جریان وجوه نقد';
							|it = 'Voce flussi di denaro';
							|pl = 'Kierunek ruchu środków pieniężnych';
							|tr = 'Nakit akışı öğesi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng lưu chuyển tiền tệ';
							|ru = 'Выбор статьи движения денежных средств';
							|en = 'Select a cash flow item'; fa = 'Select a cash flow item';
							|it = 'Scelta delle voci del flusso di denaro';
							|pl = 'Wybór pozycji przepływów pieniężnych';
							|tr = 'Nakit akışı öğeleri seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng lưu chuyển tiền tệ';
							|ru = 'Статьи движения денежных средств';
							|en = 'Cash flow items'; fa = 'اقلام جریان وجوه نقد';
							|it = 'Voci flusso di denaro';
							|pl = 'Pozycje przepływów środków pieniężnych';
							|tr = 'Nakit akışı öğeleri'");
	EndIf;
	TypesPresentation1.Insert("DMCashFlowItem", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Đơn vị tính';
							|ru = 'Единица измерения';
							|en = 'Unit'; fa = 'واحد';
							|it = 'Unità di misura';
							|pl = 'Jednosta miary';
							|tr = 'Ölçü birimi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn đơn vị tính';
							|ru = 'Выбор единицы измерения';
							|en = 'Select a unit'; fa = 'Select a unit';
							|it = 'Scelta dell''unità di misura';
							|pl = 'Wybór jednostki miary';
							|tr = 'Ölçü birimi seçimi'");
	Else
		Presentation = NStr("vi = 'Đơn vị tính';
							|ru = 'Единицы измерения';
							|en = 'Units of measure'; fa = 'واحدهای اندازه‌گیری';
							|it = 'Unità di misura';
							|pl = 'Jednostki miary';
							|tr = 'Ölçü birimleri'");
	EndIf;
	TypesPresentation1.Insert("DMMeasurementUnit", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Hàng hóa, dịch vụ';
							|ru = 'Товар, услуга';
							|en = 'Good, service'; fa = 'کالا، خدمت';
							|it = 'Articolo, servizio';
							|pl = 'Towar, usługa';
							|tr = 'Ürün, hizmet'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn mặt hàng';
							|ru = 'Выбор номенклатуры';
							|en = 'Select items'; fa = 'انتخاب اقلام';
							|it = 'Selezionare gli articoli';
							|pl = 'Wybór nomenklatury';
							|tr = 'Öğe seçimi'");
	Else
		Presentation = NStr("vi = 'Hàng hóa và dịch vụ';
							|ru = 'Товары и услуги';
							|en = 'Goods and services'; fa = 'کالاها و خدمات';
							|it = 'Articoli e servizi';
							|pl = 'Towary i usługi';
							|tr = 'Ürünler ve hizmetler'");
	EndIf;
	TypesPresentation1.Insert("DMProduct", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Ставка НДС';
							|vi = 'VAT rate';
							|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
							|it = 'Aliquota IVA';
							|pl = 'Stawka VAT';
							|tr = 'KDV oranı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор ставки НДС';
							|vi = 'Select a VAT rate';
							|en = 'Select a VAT rate'; fa = 'Select a VAT rate';
							|it = 'Выбор ставки НДС';
							|pl = 'Wybór stawki VAT';
							|tr = 'KDV oranı seçimi'");
	Else
		Presentation = NStr("ru = 'Ставки НДС';
							|vi = 'VAT rates';
							|en = 'VAT rates'; fa = 'نرخ‌های مالیات بر ارزش افزوده';
							|it = 'Aliquote IVA';
							|pl = 'Stawki VAT';
							|tr = 'KDV oranları'");
	EndIf;
	TypesPresentation1.Insert("DMVATRateUniversal", Presentation);
	
	// Emails.
	If SingularForm Then
		Presentation = NStr("vi = 'E-mail đến';
							|ru = 'Входящее письмо';
							|en = 'Incoming mail'; fa = 'ایمیل ورودی';
							|it = 'E-mail in arrivo';
							|pl = 'Przychodzący list';
							|tr = 'Gelen e-posta'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn email đến';
							|ru = 'Выбор входящего письма';
							|en = 'Select incoming email'; fa = 'Select incoming email';
							|it = 'Selezione posta in entrata';
							|pl = 'Wybór wiadomości wchodzącej';
							|tr = 'Gelen ileti seçimi'");
	Else
		Presentation = NStr("vi = 'E-mail đến';
							|ru = 'Входящие письма';
							|en = 'Incoming mails'; fa = 'ایمیل‌های ورودی';
							|it = 'Mail in entrata';
							|pl = 'Wiadomości e-mail przychodzące';
							|tr = 'Gelen e-posta'");
	EndIf;
	TypesPresentation1.Insert("DMIncomingEMail", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'E-mail đi';
							|ru = 'Исходящее письмо';
							|en = 'Outgoing mail'; fa = 'ایمیل خروجی';
							|it = 'Messaggio in uscita';
							|pl = 'List wychodzący';
							|tr = 'Giden e-posta'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn E-mail đi';
							|ru = 'Выбор исходящего письма';
							|en = 'Select outgoing email'; fa = 'Select outgoing email';
							|it = 'Selezione posta in uscita';
							|pl = 'Wybór wiadomości wychodzącej';
							|tr = 'Giden ileti seçimi'");
	Else
		Presentation = NStr("vi = 'E-mail đi';
							|ru = 'Исходящие письма';
							|en = 'Outgoing mails'; fa = 'ایمیل‌های خروجی';
							|it = 'Lettere in uscita';
							|pl = 'Wiadomości wychodzące';
							|tr = 'Giden e-posta'");
	EndIf;
	TypesPresentation1.Insert("DMOutgoingEMail", Presentation);
	
	// Working reports.
	If SingularForm Then
		Presentation = NStr("ru = 'Ежедневный отчет';
							|vi = 'Daily report';
							|en = 'Daily report'; fa = 'گزارش روزانه';
							|it = 'Report giornaliero';
							|pl = 'Codzienny raport';
							|tr = 'Günlük rapor'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор ежедневного отчета';
							|vi = 'Select daily report';
							|en = 'Select daily report'; fa = 'Select daily report';
							|it = 'Selezione report giornaliero';
							|pl = 'Wybór raportu codziennego';
							|tr = 'Günlük rapor seçimi'");
	Else
		Presentation = NStr("ru = 'Ежедневные отчеты';
							|vi = 'Daily reports';
							|en = 'Daily reports'; fa = 'گزارش‌های روزانه';
							|it = 'Report giornalieri';
							|pl = 'Codzienne raporty';
							|tr = 'Günlük raporlar'");
	EndIf;
	TypesPresentation1.Insert("DMDailyReport", Presentation);
	
	// Actual labor costs.
	If SingularForm Then
		Presentation = NStr("ru = 'Фактические трудозатраты';
							|vi = 'Actual labor costs';
							|en = 'Actual labor costs'; fa = 'Actual labor costs';
							|it = 'Costo del lavoro effettivo';
							|pl = 'Faktyczne nakłady pracy';
							|tr = 'Gerçekleşen işçilik maliyetleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор фактических трудозатрат';
							|vi = 'Select actual labor costs';
							|en = 'Select actual labor costs'; fa = 'Select actual labor costs';
							|it = 'Select actual labor costs';
							|pl = 'Select actual labor costs';
							|tr = 'Fiili işçilik maliyeti seçimi'");
	Else
		Presentation = NStr("ru = 'Фактические трудозатраты';
							|vi = 'Actual labor costs';
							|en = 'Actual labor costs'; fa = 'Actual labor costs';
							|it = 'Costo del lavoro effettivo';
							|pl = 'Faktyczne nakłady pracy';
							|tr = 'Gerçekleşen işçilik maliyetleri'");
	EndIf;
	TypesPresentation1.Insert("DMActualWork", Presentation);
	
	// The enumerations used.
	If SingularForm Then
		Presentation = NStr("vi = 'Kiểu phản hồi';
							|ru = 'Тип ответа';
							|en = 'Response type'; fa = 'نوع پاسخ';
							|it = 'Tipo di risposta';
							|pl = 'Typ odpowiedzi';
							|tr = 'Yanıt türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn kiểu phản hồi';
							|ru = 'Выбор типа ответа';
							|en = 'Select a response type'; fa = 'Select a response type';
							|it = 'Selezione del tipo di risposta';
							|pl = 'Wybór typu odpowiedzi';
							|tr = 'Yanıt türü seçimi'");
	Else
		Presentation = NStr("vi = 'Kiểu phản hồi';
							|ru = 'Типы ответа';
							|en = 'Response types'; fa = 'Response types';
							|it = 'Tipi di risposta';
							|pl = 'Typy odpowiedzi';
							|tr = 'Yanıt türleri'");
	EndIf;
	TypesPresentation1.Insert("DMEMailAnswerType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng câu hỏi thực hiện nhiệm vụ';
							|ru = 'Вид вопросов выполнения задач';
							|en = 'Question kind of task execution'; fa = 'Question kind of task execution';
							|it = 'Aspetto di problemi di esecuzione dei compiti';
							|pl = 'Rodzaj pytań wykonania zadań';
							|tr = 'Görev tamamlama soruları türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng câu hỏi thực hiện nhiệm vụ';
							|ru = 'Выбор вида вопросов выполнения задач';
							|en = 'Select a question kind of task execution'; fa = 'Select a question kind of task execution';
							|it = 'Scelta dell''aspetto di problemi di esecuzione dei compiti';
							|pl = 'Rodzaj pytań wykonania zadań';
							|tr = 'Görev tamamlama soruları türünün seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng vấn đề thực hiện nhiệm vụ';
							|ru = 'Виды вопросов выполнения задач';
							|en = 'Issue kinds of task execution'; fa = 'Issue kinds of task execution';
							|it = 'Tipi di problema di completamento dei compiti';
							|pl = 'Rodzaje pytań wykonania zadań';
							|tr = 'Görev tamamlama sorularının türleri'");
	EndIf;
	TypesPresentation1.Insert("DMIssueType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trình tự gia hạn';
							|ru = 'Порядок продления';
							|en = 'Extension procedure'; fa = 'رویه تمدید';
							|it = 'Ordine di proroga';
							|pl = 'Tryb przedłużenia';
							|tr = 'Uzatma prosedürü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trình tự gia hạn';
							|ru = 'Выбор порядка продления';
							|en = 'Select an extension procedure'; fa = 'Select an extension procedure';
							|it = 'Scelta dell''ordine di proroga';
							|pl = 'Wybór trybu przedłużenia';
							|tr = 'Uzatma prosedürü seçimi'");
	Else
		Presentation = NStr("vi = 'Trình tự gia hạn';
							|ru = 'Порядки продления';
							|en = 'Extension procedures'; fa = 'Extension procedures';
							|it = 'Ordini di proroga';
							|pl = 'Tryby przedłużenia';
							|tr = 'Uzatma prosedürleri'");
	EndIf;
	TypesPresentation1.Insert("DMProlongationProcedure", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trạng thái văn bản';
							|ru = 'Состояние документа';
							|en = 'Document state'; fa = 'وضعیت سند';
							|it = 'Stato del documento';
							|pl = 'Status dokumentu';
							|tr = 'Belge durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trạng thái chứng từ';
							|ru = 'Выбор состояния документа';
							|en = 'Select document state'; fa = 'Select document state';
							|it = 'Selezione stato documento';
							|pl = 'Wybór statusu dokumentu';
							|tr = 'Belge durumu seçimi'");
	Else
		Presentation = NStr("vi = 'Trạng thái văn bản';
							|ru = 'Состояния документов';
							|en = 'Document states'; fa = 'وضعیت‌های سند';
							|it = 'Stati documenti';
							|pl = 'Statusy dokumentów';
							|tr = 'Belge durumları'");
	EndIf;
	TypesPresentation1.Insert("DMDocumentStatus", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trạng thái cuộc họp';
							|ru = 'Состояние мероприятия';
							|en = 'Event state'; fa = 'Event state';
							|it = 'Stato evento';
							|pl = 'Status wydarzenia';
							|tr = 'Etkinlik durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trạng thái cuộc họp';
							|ru = 'Выбор состояния мероприятия';
							|en = 'Select event state'; fa = 'Select event state';
							|it = 'Selezione stato dell''evento';
							|pl = 'Wybór statusu wydarzenia';
							|tr = 'Etkinlik durumu seçimi'");
	Else
		Presentation = NStr("vi = 'Trạng thái cuộc họp';
							|ru = 'Состояния мероприятий';
							|en = 'Event states'; fa = 'Event states';
							|it = 'Stati eventi';
							|pl = 'Statusy wydarzeń';
							|tr = 'Etkinliklerin durumları'");
	EndIf;
	TypesPresentation1.Insert("DMMeetingStatus", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trạng thái biên bản cuộc họp';
							|ru = 'Состояние протокола мероприятия';
							|en = 'Event protocol state'; fa = 'Event protocol state';
							|it = 'Stato del protocollo dell''evento';
							|pl = 'Status protokołu wydarzenia';
							|tr = 'Etkinlik protokol durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trạng thái biên bản cuộc họp';
							|ru = 'Выбор состояния протокола мероприятия';
							|en = 'Select an event protocol state'; fa = 'Select an event protocol state';
							|it = 'Selezione stato del protocollo dell''evento';
							|pl = 'Wybór statusu protokołu wydarzenia';
							|tr = 'Etkinlik protokol durumu seçimi'");
	Else
		Presentation = NStr("vi = 'Trạng thái biên bản cuộc họp';
							|ru = 'Состояния протоколов мероприятий';
							|en = 'Event protocol states'; fa = 'Event protocol states';
							|it = 'Stati dei protocolli degli eventi';
							|pl = 'Statusy protokołów wydarzeń';
							|tr = 'Etkinliklerin protokol durumları'");
	EndIf;
	TypesPresentation1.Insert("DMMeetingMinutesItemStatus", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Pháp nhân\cá nhân';
							|ru = 'Юридическое\физическое лицо';
							|en = 'Business entity\person'; fa = 'Business entity\person';
							|it = 'Entità giuridica \ persona fisica';
							|pl = 'Osoba prawna\fizyczna';
							|tr = 'Tüzel\gerçek kişi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn pháp nhân\cá nhân';
							|ru = 'Выбор юр\физ лица';
							|en = 'Select a legal entity\person'; fa = 'Select a legal entity\person';
							|it = 'Selezione persona giuridica\fisica';
							|pl = 'Wybór osoby prawnej\fizycznej';
							|tr = 'Tüzel\gerçek kişi seçimi'");
	Else
		Presentation = NStr("vi = 'Pháp nhân\cá nhân';
							|ru = 'Юридическое\физическое лица';
							|en = 'Legal entity\person'; fa = 'Legal entity\person';
							|it = 'Persone giuridiche \ fisiche';
							|pl = 'Osoba prawna\fizyczna';
							|tr = 'Tüzel\gerçek kişi'");
	EndIf;
	TypesPresentation1.Insert("DMLegalPrivatePerson", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Ставка НДС';
							|vi = 'VAT rate';
							|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
							|it = 'Aliquota IVA';
							|pl = 'Stawka VAT';
							|tr = 'KDV oranı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор ставки НДС';
							|vi = 'Select a VAT rate';
							|en = 'Select a VAT rate'; fa = 'Select a VAT rate';
							|it = 'Выбор ставки НДС';
							|pl = 'Wybór stawki VAT';
							|tr = 'KDV oranı seçimi'");
	Else
		Presentation = NStr("ru = 'Ставки НДС';
							|vi = 'VAT rates';
							|en = 'VAT rates'; fa = 'نرخ‌های مالیات بر ارزش افزوده';
							|it = 'Aliquote IVA';
							|pl = 'Stawki VAT';
							|tr = 'KDV oranları'");
	EndIf;
	TypesPresentation1.Insert("DMVATRate", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Phương án ký';
							|ru = 'Вариант подписания';
							|en = 'How to sign'; fa = 'How to sign';
							|it = 'Variante di firma';
							|pl = 'Wariant podpisania';
							|tr = 'İmza seçeneği'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn phương án ký';
							|ru = 'Выбор варианта подписания';
							|en = 'Select how to sign'; fa = 'Select how to sign';
							|it = 'Scelta di un''opzione di firma';
							|pl = 'Wybór wariantu podpisania';
							|tr = 'İmza seçeneği seçimi'");
	Else
		Presentation = NStr("vi = 'Phương án ký';
							|ru = 'Варианты подписания';
							|en = 'Signing options'; fa = 'Signing options';
							|it = 'Opzioni di firma';
							|pl = 'Warianty podpisania';
							|tr = 'İmza seçenekleri'");
	EndIf;
	TypesPresentation1.Insert("DMSignatureOption", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Kiểu thông tin liên hệ';
							|ru = 'Тип контактной информации';
							|en = 'Contact information type'; fa = 'نوع اطلاعات تماس';
							|it = 'Tipo di informazione di contatto';
							|pl = 'Rodzaj informacji kontaktowych';
							|tr = 'İletişim bilgileri türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn kiểu thông tin liên hệ';
							|ru = 'Выбор типа контактной информации';
							|en = 'Select a contact information type'; fa = 'Select a contact information type';
							|it = 'Selezione del tipo di informazione di contatto';
							|pl = 'Wybór typu informacji kontaktowych ';
							|tr = 'İletişim bilgileri türü seçimi'");
	Else
		Presentation = NStr("vi = 'Kiểu thông tin liên hệ';
							|ru = 'Типы контактной информации';
							|en = 'Contact information types'; fa = 'انواع اطلاعات تماس';
							|it = 'Tipi di informazione di contatto';
							|pl = 'Rodzaje informacji kontaktowych';
							|tr = 'İletişim bilgisi tipleri'");
	EndIf;
	TypesPresentation1.Insert("DMContactInformationType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thể loại hồ sơ';
							|ru = 'Категория дел';
							|en = 'Case category'; fa = 'Case category';
							|it = 'Categoria pratiche';
							|pl = 'Kategoria spraw';
							|tr = 'Yapılacaklar öğesi kategorisi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thể loại hồ sơ';
							|ru = 'Выбор категории дел';
							|en = 'Select a case category'; fa = 'Select a case category';
							|it = 'Selezione categoria pratiche';
							|pl = 'Wybór kategorii spraw';
							|tr = 'Yapılacaklar öğesi kategorisinin seçimi'");
	Else
		Presentation = NStr("vi = 'Thể loại hồ sơ';
							|ru = 'Категории дел';
							|en = 'Case categories'; fa = 'Case categories';
							|it = 'Categorie pratiche';
							|pl = 'Kategorie spraw';
							|tr = 'Yapılacaklar öğesi kategorileri'");
	EndIf;
	TypesPresentation1.Insert("DMCategoriesOfCases", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Ngày trong tuần';
							|ru = 'День недели';
							|en = 'Week day'; fa = 'روز هفته';
							|it = 'Giorno della settimana';
							|pl = 'Dzień tygodnia';
							|tr = 'Haftanın günü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn ngày trong tuần';
							|ru = 'Выбор дня недели';
							|en = 'Select a week day'; fa = 'Select a week day';
							|it = 'Scelta del giorno della settimana';
							|pl = 'Wybór dnia tygodnia';
							|tr = 'Haftanın günü seçimi'");
	Else
		Presentation = NStr("vi = 'Ngày trong tuần';
							|ru = 'Дни недели';
							|en = 'Week days'; fa = 'روزهای هفته';
							|it = 'Giorni della settimana';
							|pl = 'Dni tygodnia';
							|tr = 'İş günleri'");
	EndIf;
	TypesPresentation1.Insert("DMDaysOfTheWeek", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng ngày';
							|ru = 'Вид дня';
							|en = 'Day type'; fa = 'نوع روز';
							|it = 'Tipo del giorno';
							|pl = 'Rodzaj dnia';
							|tr = 'Gün türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng ngày';
							|ru = 'Выбор вида дня';
							|en = 'Select a day kind'; fa = 'Select a day kind';
							|it = 'Selezione del tipo di giorno';
							|pl = 'Wybór dnia tygodnia';
							|tr = 'Gün türü seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng ngày';
							|ru = 'Виды дней';
							|en = 'Day kinds'; fa = 'Day kinds';
							|it = 'Tipi di giorni';
							|pl = 'Rodzaje dni';
							|tr = 'Gün türleri'");
	EndIf;
	TypesPresentation1.Insert("DMKindsOfDays", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Chính sách ghi nhận thời gian làm việc';
							|ru = 'Политика учета рабочего времени';
							|en = 'Working time tracking policy'; fa = 'Working time tracking policy';
							|it = 'Politica contabile dell''orario di lavoro';
							|pl = 'Polityka ewidencji czasu pracy';
							|tr = 'Çalışma zamanının raporlanma politikası'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn chính sách ghi nhận thời gian làm việc';
							|ru = 'Выбор политики учета рабочего времени';
							|en = 'Select a working time tracking policy'; fa = 'Select a working time tracking policy';
							|it = 'Selezione politica contabile dell''orario di lavoro.';
							|pl = 'Wybór polityki ewidencji czasu pracy';
							|tr = 'Çalışma zamanının raporlanma politikası seçimi'");
	Else
		Presentation = NStr("vi = 'Chính sách ghi nhận thời gian làm việc';
							|ru = 'Политики учета рабочего времени';
							|en = 'Working time tracking policies'; fa = 'Working time tracking policies';
							|it = 'Politiche contabili dell''orario di lavoro';
							|pl = 'Polityki ewidencji czasu pracy';
							|tr = 'Çalışma zamanının raporlanma politikaları'");
	EndIf;
	TypesPresentation1.Insert("DMTimeTrackingPolicy", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Kiểu phản hồi';
							|ru = 'Тип ответа';
							|en = 'Response type'; fa = 'نوع پاسخ';
							|it = 'Tipo di risposta';
							|pl = 'Typ odpowiedzi';
							|tr = 'Yanıt türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn kiểu phản hồi';
							|ru = 'Выбор типа ответа';
							|en = 'Select a response type'; fa = 'Select a response type';
							|it = 'Selezione del tipo di risposta';
							|pl = 'Wybór typu odpowiedzi';
							|tr = 'Yanıt türü seçimi'");
	Else
		Presentation = NStr("vi = 'Kiểu phản hồi';
							|ru = 'Типы ответа';
							|en = 'Response types'; fa = 'Response types';
							|it = 'Tipi di risposta';
							|pl = 'Typy odpowiedzi';
							|tr = 'Yanıt türleri'");
	EndIf;
	TypesPresentation1.Insert("DMIncomingEMailAnswerType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trạng thái mời họp';
							|ru = 'Состояние приглашения';
							|en = 'Invitation state'; fa = 'Invitation state';
							|it = 'Stato di invito';
							|pl = 'Status zaproszenia';
							|tr = 'Davet durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trạng thái mời họp';
							|ru = 'Выбор состояния приглашения';
							|en = 'Select an invitation state'; fa = 'Select an invitation state';
							|it = 'Selezione stato dell''invito';
							|pl = 'Wybór statusu zaproszenia';
							|tr = 'Davet durumu seçimi'");
	Else
		Presentation = NStr("vi = 'Trạng thái mời họp';
							|ru = 'Состояния приглашения';
							|en = 'Invitation states'; fa = 'Invitation states';
							|it = 'Stati di invito';
							|pl = 'Statusy zaproszenia';
							|tr = 'Davet durumu'");
	EndIf;
	TypesPresentation1.Insert("DMInvitationStatus", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Результат приглашения';
							|vi = 'Invitation result';
							|en = 'Invitation result'; fa = 'نتیجه دعوت';
							|it = 'Risultato invito';
							|pl = 'Wynik zaproszenia';
							|tr = 'Davetin sonucu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор результата приглашения';
							|vi = 'Select an invitation result';
							|en = 'Select an invitation result'; fa = 'Select an invitation result';
							|it = 'Select an invitation result';
							|pl = 'Select an invitation result';
							|tr = 'Davet sonucu seçimi'");
	Else
		Presentation = NStr("ru = 'Результаты приглашения';
							|vi = 'Invitation results';
							|en = 'Invitation results'; fa = 'Invitation results';
							|it = 'Risultati invito';
							|pl = 'Wyniki zaproszenia';
							|tr = 'Davet sonuçları'");
	EndIf;
	TypesPresentation1.Insert("DMInvitationResult", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Общий результат приглашения';
							|vi = 'General invitation result';
							|en = 'General invitation result'; fa = 'General invitation result';
							|it = 'General invitation result';
							|pl = 'General invitation result';
							|tr = 'Genel davet sonucu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор общего результата приглашения';
							|vi = 'Select a general invitation result';
							|en = 'Select a general invitation result'; fa = 'Select a general invitation result';
							|it = 'Select a general invitation result';
							|pl = 'Select a general invitation result';
							|tr = 'Genel davet sonucu seçimi'");
	Else
		Presentation = NStr("ru = 'Общие результаты приглашения';
							|vi = 'General invitation results';
							|en = 'General invitation results'; fa = 'General invitation results';
							|it = 'Risultati generali invito';
							|pl = 'Wspólne wyniki zaproszenia';
							|tr = 'Paylaşımlı davet sonuçları'");
	EndIf;
	TypesPresentation1.Insert("DMGeneralInvitationResult", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Результат согласования';
							|vi = 'Approval result';
							|en = 'Approval result'; fa = 'نتیجه تأیید';
							|it = 'Risultato della negoziazione';
							|pl = 'Wynik uzgodnienia';
							|tr = 'Anlaşma sonucu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор результата согласования';
							|vi = 'Select an approval result';
							|en = 'Select an approval result'; fa = 'Select an approval result';
							|it = 'Select an approval result';
							|pl = 'Select an approval result';
							|tr = 'Onay sonucu seçimi'");
	Else
		Presentation = NStr("ru = 'Результаты согласования';
							|vi = 'Approval results ';
							|en = 'Approval results '; fa = 'نتایج تأیید';
							|it = 'Risultati accordo';
							|pl = 'Wyniki uzgodnienia';
							|tr = 'Mutabakat sonuçları'");
	EndIf;
	TypesPresentation1.Insert("DMApprovalResult", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Результат утверждения';
							|vi = 'Confirmation result';
							|en = 'Confirmation result'; fa = 'نتیجه تصدیق';
							|it = 'Risultato di conferma';
							|pl = 'Wynik zatwierdzenia';
							|tr = 'Onay sonucu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор результата утверждения';
							|vi = 'Select a confirmation result';
							|en = 'Select a confirmation result'; fa = 'Select a confirmation result';
							|it = 'Select a confirmation result';
							|pl = 'Select a confirmation result';
							|tr = 'Tasdik sonucu seçimi'");
	Else
		Presentation = NStr("ru = 'Результаты утверждения';
							|vi = 'Confirmation results';
							|en = 'Confirmation results'; fa = 'Confirmation results';
							|it = 'Risultati conferma';
							|pl = 'Wyniki zatwierdzenia';
							|tr = 'Onay sonuçları'");
	EndIf;
	TypesPresentation1.Insert("DMConfirmationResult", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Результат регистрации';
							|vi = 'Registration result';
							|en = 'Registration result'; fa = 'نتیجه ثبت';
							|it = 'Risultato registrazione';
							|pl = 'Wynik rejestracji';
							|tr = 'Kayıt sonucu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор результата регистрации';
							|vi = 'Select a registration result';
							|en = 'Select a registration result'; fa = 'Select a registration result';
							|it = 'Select a registration result';
							|pl = 'Select a registration result';
							|tr = 'Kayıt sonucu seçimi'");
	Else
		Presentation = NStr("ru = 'Результаты регистрации';
							|vi = 'Registration results';
							|en = 'Registration results'; fa = 'Registration results';
							|it = 'Risultati registrazione';
							|pl = 'Wyniki rejestracji';
							|tr = 'Kayıt sonuçları'");
	EndIf;
	TypesPresentation1.Insert("DMRegistrationResult", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Mục tin / thông tin bổ sung';
							|ru = 'Дополнительный реквизит / сведение';
							|en = 'Additional attribute or information record'; fa = 'ویژگی تکمیلی یا رکورد اطلاعاتی';
							|it = 'Requisito/informazione aggiuntivi';
							|pl = 'Dodatkowy rekwizyt / informacja';
							|tr = 'Ek öznitelik / bilgi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn mục tin bổ sung';
							|ru = 'Выбор дополнительного реквизита';
							|en = 'Select an additional attribute'; fa = 'Select an additional attribute';
							|it = 'Scelta dell''attributo aggiuntivo';
							|pl = 'Wybór atrybutu dodatkowego';
							|tr = 'Ek öznitelik seçimi'");
	Else
		Presentation = NStr("vi = 'Mục tin và thông tin bổ sung';
							|ru = 'Дополнительные реквизиты и сведения';
							|en = 'Additional attributes and information'; fa = 'Additional attributes and information';
							|it = 'Requisiti e informazioni aggiuntivi';
							|pl = 'Dodatkowe rekwizyty i informacje';
							|tr = 'Ek öznitelikler ve bilgiler'");
	EndIf;
	TypesPresentation1.Insert("DMAdditionalProperty", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Способ указания времени';
							|vi = 'Time specification method';
							|en = 'Time specification method'; fa = 'روش تعیین زمان';
							|it = 'Metodo di indicazione di tempo';
							|pl = 'Sposób wskazania czasu';
							|tr = 'Zaman belirtme yöntemi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор способа указания времени';
							|vi = 'Select a time specification method';
							|en = 'Select a time specification method'; fa = 'Select a time specification method';
							|it = 'Select a time specification method';
							|pl = 'Select a time specification method';
							|tr = 'Zaman belirtme yöntemi seçimi'");
	Else
		Presentation = NStr("ru = 'Способы указания времени';
							|vi = 'Time specification methods ';
							|en = 'Time specification methods '; fa = 'Time specification methods ';
							|it = 'Metodi di indicazione di tempo';
							|pl = 'Sposoby wskazania czasu';
							|tr = 'Zaman belirtme yöntemleri'");
	EndIf;
	TypesPresentation1.Insert("DMTimeInputMethod", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Вариант маршрутизации задач';
							|vi = 'Task routing option';
							|en = 'Task routing option'; fa = 'Task routing option';
							|it = 'Task routing option';
							|pl = 'Task routing option';
							|tr = 'Görev yönlendirme yöntemi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор варианта маршрутизации задач';
							|vi = 'Select a task routing option';
							|en = 'Select a task routing option'; fa = 'Select a task routing option';
							|it = 'Select a task routing option';
							|pl = 'Select a task routing option';
							|tr = 'Görev yönlendirme yöntemi seçimi'");
	Else
		Presentation = NStr("ru = 'Варианты маршрутизации задач';
							|vi = 'Task routing options';
							|en = 'Task routing options'; fa = 'Task routing options';
							|it = 'Varianti di routing dei compiti';
							|pl = 'Warianty trasowania zadań';
							|tr = 'Görev yönlendirme seçenekleri'");
	EndIf;
	TypesPresentation1.Insert("DMApprovalType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Порядок выполнения задач';
							|vi = 'Task fulfillment procedure ';
							|en = 'Task fulfillment procedure '; fa = 'Task fulfillment procedure ';
							|it = 'Ordine di esecuzione dei compiti';
							|pl = 'Tryb wykonania zadań';
							|tr = 'Görev gerçekleştirme sırası'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор порядка выполнения задач';
							|vi = 'Select a task execution order';
							|en = 'Select a task execution order'; fa = 'Select a task execution order';
							|it = 'Select a task execution order';
							|pl = 'Select a task execution order';
							|tr = 'Görev yürütme sırası seçimi'");
	Else
		Presentation = NStr("ru = 'Порядок выполнения задач';
							|vi = 'Task fulfillment procedure ';
							|en = 'Task fulfillment procedure '; fa = 'Task fulfillment procedure ';
							|it = 'Ordine di esecuzione dei compiti';
							|pl = 'Tryb wykonania zadań';
							|tr = 'Görev gerçekleştirme sırası'");
	EndIf;
	TypesPresentation1.Insert("DMTaskExecutionOrder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Порядок согласования';
							|vi = 'Approval procedure';
							|en = 'Approval procedure'; fa = 'رویه تأیید';
							|it = 'Ordine di omologazione';
							|pl = 'Tryb uzgodnienia';
							|tr = 'Anlaşma süresi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор порядка согласования';
							|vi = 'Select an approval order';
							|en = 'Select an approval order'; fa = 'Select an approval order';
							|it = 'Select an approval order';
							|pl = 'Select an approval order';
							|tr = 'Onay sırası seçimi'");
	Else
		Presentation = NStr("ru = 'Порядок согласования';
							|vi = 'Approval procedure';
							|en = 'Approval procedure'; fa = 'رویه تأیید';
							|it = 'Ordine di omologazione';
							|pl = 'Tryb uzgodnienia';
							|tr = 'Anlaşma süresi'");
	EndIf;
	TypesPresentation1.Insert("DMApprovalOrder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Важность писем';
							|vi = 'Email importance ';
							|en = 'Email importance '; fa = 'Email importance ';
							|it = 'Importanza posta';
							|pl = 'Ważność wiadomości';
							|tr = 'Mektup önemliliği'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор важности писем';
							|vi = 'Select email importance';
							|en = 'Select email importance'; fa = 'Select email importance';
							|it = 'Select email importance';
							|pl = 'Select email importance';
							|tr = 'E-posta önemi seçimi'");
	Else
		Presentation = NStr("ru = 'Важность писем';
							|vi = 'Email importance ';
							|en = 'Email importance '; fa = 'Email importance ';
							|it = 'Importanza posta';
							|pl = 'Ważność wiadomości';
							|tr = 'Mektup önemliliği'");
	EndIf;
	TypesPresentation1.Insert("DMEMailImportance", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Состояние бизнес-процесса';
							|vi = 'Business process state';
							|en = 'Business process state'; fa = 'وضعیت فرایند تجاری';
							|it = 'Business process state';
							|pl = 'Business process state';
							|tr = 'İş süreci durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор бизнес-процесса';
							|vi = 'Select a business process';
							|en = 'Select a business process'; fa = 'Select a business process';
							|it = 'Select a business process';
							|pl = 'Select a business process';
							|tr = 'İş süreci seçimi'");
	Else
		Presentation = NStr("ru = 'Состояния бизнес-процессов';
							|vi = 'Business process states';
							|en = 'Business process states'; fa = 'وضعیت‌های فرایند تجاری';
							|it = 'Business process states';
							|pl = 'Business process states';
							|tr = 'İş süreçleri durumları'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessState", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Вариант маршрутизации задач';
							|vi = 'Task routing option';
							|en = 'Task routing option'; fa = 'Task routing option';
							|it = 'Task routing option';
							|pl = 'Task routing option';
							|tr = 'Görev yönlendirme yöntemi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор варианта маршрутизации задач';
							|vi = 'Select a task routing option';
							|en = 'Select a task routing option'; fa = 'Select a task routing option';
							|it = 'Select a task routing option';
							|pl = 'Select a task routing option';
							|tr = 'Görev yönlendirme yöntemi seçimi'");
	Else
		Presentation = NStr("ru = 'Варианты маршрутизации задач';
							|vi = 'Task routing options';
							|en = 'Task routing options'; fa = 'Task routing options';
							|it = 'Varianti di routing dei compiti';
							|pl = 'Warianty trasowania zadań';
							|tr = 'Görev yönlendirme seçenekleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessRoutingType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Условие рассмотрения предшественников этапа';
							|vi = 'Review condition of step predecessors';
							|en = 'Review condition of step predecessors'; fa = 'Review condition of step predecessors';
							|it = 'Review condition of step predecessors';
							|pl = 'Review condition of step predecessors';
							|tr = 'Aşama öncüllerini inceleme koşulu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор условия рассмотрения предшественников этапа';
							|vi = 'Select a review condition of step predecessors';
							|en = 'Select a review condition of step predecessors'; fa = 'Select a review condition of step predecessors';
							|it = 'Select a review condition of step predecessors';
							|pl = 'Select a review condition of step predecessors';
							|tr = 'Aşama öncüllerini inceleme koşulu seçimi'");
	Else
		Presentation = NStr("ru = 'Условия рассмотрения предшественников этапа';
							|vi = 'Review conditions of step predecessors';
							|en = 'Review conditions of step predecessors'; fa = 'Review conditions of step predecessors';
							|it = 'Condizioni di valutazione dei precedenti della fase';
							|pl = 'Warunki rozpatrzenia poprzedników etapu';
							|tr = 'Aşama öncüllerini değerlendirme şartları'");
	EndIf;
	TypesPresentation1.Insert("DMPredecessorsStageConsiderationCondition", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Вариант важности задачи';
							|vi = 'Task priority option';
							|en = 'Task priority option'; fa = 'Task priority option';
							|it = 'Task priority option';
							|pl = 'Task priority option';
							|tr = 'Görev önem seviyesi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор варианта важности задачи';
							|vi = 'Select a task priority option';
							|en = 'Select a task priority option'; fa = 'Select a task priority option';
							|it = 'Select a task priority option';
							|pl = 'Select a task priority option';
							|tr = 'Görev önem seviyesi seçimi'");
	Else
		Presentation = NStr("ru = 'Варианты важности задачи';
							|vi = 'Task importance options';
							|en = 'Task importance options'; fa = 'Task importance options';
							|it = 'Varianti dell''importanza del compito';
							|pl = 'Warianty ważności zadania';
							|tr = 'Görev önemi seçenekleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessTaskImportance", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Вариант важности задачи';
							|vi = 'Task priority option';
							|en = 'Task priority option'; fa = 'Task priority option';
							|it = 'Task priority option';
							|pl = 'Task priority option';
							|tr = 'Görev önem seviyesi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор варианта важности задачи';
							|vi = 'Select a task priority option';
							|en = 'Select a task priority option'; fa = 'Select a task priority option';
							|it = 'Select a task priority option';
							|pl = 'Select a task priority option';
							|tr = 'Görev önem seviyesi seçimi'");
	Else
		Presentation = NStr("ru = 'Варианты важности задачи';
							|vi = 'Task importance options';
							|en = 'Task importance options'; fa = 'Task importance options';
							|it = 'Varianti dell''importanza del compito';
							|pl = 'Warianty ważności zadania';
							|tr = 'Görev önemi seçenekleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessImportance", Presentation);
	
	// Typed tasks.
	If SingularForm Then
		Presentation = NStr("ru = 'Задача исполнителя';
							|vi = 'Task of assignee';
							|en = 'Task of assignee'; fa = 'Task of assignee';
							|it = 'Compito dell''esecutore';
							|pl = 'Zadanie wykonawcy';
							|tr = 'Atanan görevi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор задачи исполнителя';
							|vi = 'Select task of assignee';
							|en = 'Select task of assignee'; fa = 'Select task of assignee';
							|it = 'Select task of assignee';
							|pl = 'Select task of assignee';
							|tr = 'Yürütücü görevi seçimi'");
	Else
		Presentation = NStr("ru = 'Задачи исполнителей';
							|vi = 'Tasks of assignees';
							|en = 'Tasks of assignees'; fa = 'Tasks of assignees';
							|it = 'Tasks of assignees';
							|pl = 'Tasks of assignees';
							|tr = 'Yürütücü görevleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessTask", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessOrderTaskCheckup", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessApprovalTaskApproval", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessApprovalTaskCheckup", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessConfirmationTaskConfirmation", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessConfirmationTaskCheckup", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessRegistrationTaskRegistration", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessRegistrationTaskCheckup", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessPerfomanceTaskCheckup", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessConsiderationTaskAcquaint", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessIssuesSolutionTaskQuestion", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessIssuesSolutionTaskAnswer", Presentation);
	
	// Business process templates.
	If SingularForm Then
		Presentation = NStr("ru = 'Шаблон %1';
							|vi = '%1 template';
							|en = '%1 template'; fa = '%1 template';
							|it = '%1 template';
							|pl = '%1 template';
							|tr = 'Şablon %1'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор шаблона %1';
							|vi = 'Select the %1 template';
							|en = 'Select the %1 template'; fa = 'Select the %1 template';
							|it = 'Select the %1 template';
							|pl = 'Select the %1 template';
							|tr = 'Şablon %1 seçimi'");
	Else
		Presentation = NStr("ru = 'Шаблоны %1';
							|vi = '%1 templates';
							|en = '%1 templates'; fa = '%1 templates';
							|it = '%1 templates';
							|pl = '%1 templates';
							|tr = 'Şablonlar %1'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessOrderTemplate", StrTemplate(Presentation, NStr("ru = 'поручения';
																								|vi = 'instructions';
																								|en = 'instructions'; fa = 'instructions';
																								|it = 'instructions';
																								|pl = 'instructions';
																								|tr = 'talimat'")));
	TypesPresentation1.Insert("DMBusinessProcessConsiderationTemplate", StrTemplate(Presentation, NStr("ru = 'рассмотрения';
																										|vi = 'reviews';
																										|en = 'reviews'; fa = 'reviews';
																										|it = 'reviews';
																										|pl = 'reviews';
																										|tr = 'inceleme'")));
	TypesPresentation1.Insert("DMBusinessProcessRegistrationTemplate", StrTemplate(Presentation, NStr("ru = 'регистрации';
																										|vi = 'registrations';
																										|en = 'registrations'; fa = 'registrations';
																										|it = 'registrations';
																										|pl = 'registrations';
																										|tr = 'kayıt'")));
	TypesPresentation1.Insert("DMBusinessProcessApprovalTemplate", StrTemplate(Presentation, NStr("ru = 'согласования';
																									|vi = 'approvals';
																									|en = 'approvals'; fa = 'approvals';
																									|it = 'approvals';
																									|pl = 'approvals';
																									|tr = 'kayıt'")));
	TypesPresentation1.Insert("DMBusinessProcessConfirmationTemplate", StrTemplate(Presentation, NStr("ru = 'утверждения';
																										|vi = 'confirmations';
																										|en = 'confirmations'; fa = 'confirmations';
																										|it = 'confirmations';
																										|pl = 'confirmations';
																										|tr = 'tasdik'")));
	TypesPresentation1.Insert("DMBusinessProcessPerformanceTemplate", StrTemplate(Presentation, NStr("ru = 'исполнения';
																									|vi = 'executions';
																									|en = 'executions'; fa = 'executions';
																									|it = 'executions';
																									|pl = 'executions';
																									|tr = 'yürütme'")));
	TypesPresentation1.Insert("DMBusinessProcessAcquaintanceTemplate", StrTemplate(Presentation, NStr("ru = 'ознакомления';
																										|vi = 'previews';
																										|en = 'previews'; fa = 'previews';
																										|it = 'previews';
																										|pl = 'previews';
																										|tr = 'bilgilendirme'")));
	TypesPresentation1.Insert("DMCompoundBusinessProcessTemplate", StrTemplate(Presentation, NStr("ru = 'составных бизнес процессов';
																									|vi = 'multiple business processes';
																									|en = 'multiple business processes'; fa = 'multiple business processes';
																									|it = 'multiple business processes';
																									|pl = 'multiple business processes';
																									|tr = 'bileşik iş süreçleri'")));
	
	// Business processes.
	If SingularForm Then
		Presentation = NStr("ru = 'Поручение';
							|vi = 'Instruction';
							|en = 'Instruction'; fa = 'دستورالعمل';
							|it = 'Instruction';
							|pl = 'Instruction';
							|tr = 'Talimat'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор поручения';
							|vi = 'Select an instruction';
							|en = 'Select an instruction'; fa = 'Select an instruction';
							|it = 'Select an instruction';
							|pl = 'Select an instruction';
							|tr = 'Talimat seçimi'");
	Else
		Presentation = NStr("ru = 'Поручения';
							|vi = 'Instructions';
							|en = 'Instructions'; fa = 'دستورالعمل‌ها';
							|it = 'Instructions';
							|pl = 'Instructions';
							|tr = 'Talimatlar'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessOrder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Рассмотрение';
							|vi = 'Review';
							|en = 'Review'; fa = 'بررسی';
							|it = 'Review';
							|pl = 'Review';
							|tr = 'Değerlendirme'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор рассмотрения';
							|vi = 'Select a review';
							|en = 'Select a review'; fa = 'Select a review';
							|it = 'Select a review';
							|pl = 'Select a review';
							|tr = 'Değerlendirme seçimi'");
	Else
		Presentation = NStr("ru = 'Рассмотрения';
							|vi = 'Reviews';
							|en = 'Reviews'; fa = 'Reviews';
							|it = 'Reviews';
							|pl = 'Reviews';
							|tr = 'Değerlendirmeler'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessConsideration", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Регистрация';
							|vi = 'Registration';
							|en = 'Registration'; fa = 'ثبت';
							|it = 'Registration';
							|pl = 'Registration';
							|tr = 'Kayıt'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор регистрации';
							|vi = 'Select a registration';
							|en = 'Select a registration'; fa = 'Select a registration';
							|it = 'Select a registration';
							|pl = 'Select a registration';
							|tr = 'Kayıt seçimi'");
	Else
		Presentation = NStr("ru = 'Регистрации';
							|vi = 'Registrations';
							|en = 'Registrations'; fa = 'Registrations';
							|it = 'Registrations';
							|pl = 'Registrations';
							|tr = 'Kayıtlar'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessRegistration", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Согласование';
							|vi = 'Approval';
							|en = 'Approval'; fa = 'تأیید';
							|it = 'Approval';
							|pl = 'Approval';
							|tr = 'Onay'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор согласования';
							|vi = 'Select an approval';
							|en = 'Select an approval'; fa = 'Select an approval';
							|it = 'Select an approval';
							|pl = 'Select an approval';
							|tr = 'Onay seçimi'");
	Else
		Presentation = NStr("ru = 'Согласования';
							|vi = 'Approvals';
							|en = 'Approvals'; fa = 'Approvals';
							|it = 'Approvals';
							|pl = 'Approvals';
							|tr = 'Onaylar'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessApproval", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessApproval_1.2.1.11", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Утверждение';
							|vi = 'Confirmation';
							|en = 'Confirmation'; fa = 'تأیید';
							|it = 'Confirmation';
							|pl = 'Confirmation';
							|tr = 'Tasdik'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор утверждения';
							|vi = 'Select confirmation';
							|en = 'Select confirmation'; fa = 'انتخاب تأیید';
							|it = 'Select confirmation';
							|pl = 'Select confirmation';
							|tr = 'Tasdik seçimi'");
	Else
		Presentation = NStr("ru = 'Утверждения';
							|vi = 'Confirmations';
							|en = 'Confirmations'; fa = 'Confirmations';
							|it = 'Confirmations';
							|pl = 'Confirmations';
							|tr = 'Tasdikler'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessConfirmation", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Исполнение';
							|vi = 'Execution';
							|en = 'Execution'; fa = 'اجرا';
							|it = 'Execution';
							|pl = 'Execution';
							|tr = 'Yürütme'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор исполнения';
							|vi = 'Select execution';
							|en = 'Select execution'; fa = 'Select execution';
							|it = 'Select execution';
							|pl = 'Select execution';
							|tr = 'Yürütme seçimi'");
	Else
		Presentation = NStr("ru = 'Исполнения';
							|vi = 'Executions';
							|en = 'Executions'; fa = 'Executions';
							|it = 'Executions';
							|pl = 'Executions';
							|tr = 'Yürütme işlemleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessPerformance", Presentation);
	TypesPresentation1.Insert("DMBusinessProcessPerformance_1.2.1.11", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Ознакомление';
							|vi = 'Preview';
							|en = 'Preview'; fa = 'پیش‌نمایش';
							|it = 'Preview';
							|pl = 'Preview';
							|tr = 'Bilgilendirme'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор ознакомления';
							|vi = 'Select preview';
							|en = 'Select preview'; fa = 'Select preview';
							|it = 'Select preview';
							|pl = 'Select preview';
							|tr = 'Bilgilendirme seçimi'");
	Else
		Presentation = NStr("ru = 'Ознакомления';
							|vi = 'Previews';
							|en = 'Previews'; fa = 'Previews';
							|it = 'Previews';
							|pl = 'Previews';
							|tr = 'Bilgilendirme işlemleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessAcquaintance", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Решение вопросов выполнения задач';
							|vi = 'Resolve Task execution issues';
							|en = 'Resolve Task execution issues'; fa = 'Resolve Task execution issues';
							|it = 'Risoluzione dei problemi di completamento dei compiti';
							|pl = 'Rozwiązywania spraw wykonania zadań';
							|tr = 'Soru çözümleri görev gerçekleştirme'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор решения вопросов выполнения задач';
							|vi = 'Select resolve tasks execution issues';
							|en = 'Select resolve tasks execution issues'; fa = 'Select resolve tasks execution issues';
							|it = 'Select resolve tasks execution issues';
							|pl = 'Select resolve tasks execution issues';
							|tr = 'Görev yürütme soruları çözüm seçimi'");
	Else
		Presentation = NStr("ru = 'Решения вопросов выполнения задач';
							|vi = 'Resolve tasks execution issues';
							|en = 'Resolve tasks execution issues'; fa = 'Resolve tasks execution issues';
							|it = 'Resolve tasks execution issues';
							|pl = 'Resolve tasks execution issues';
							|tr = 'Görev yürütme soruları çözümleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessIssuesSolution", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Обработки внутреннего документа';
							|vi = 'Internal document processing';
							|en = 'Internal document processing'; fa = 'Internal document processing';
							|it = 'Internal document processing';
							|pl = 'Internal document processing';
							|tr = 'Dahili belge işlemleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор обработки внутреннего документа';
							|vi = 'Select internal document processing';
							|en = 'Select internal document processing'; fa = 'Select internal document processing';
							|it = 'Select internal document processing';
							|pl = 'Select internal document processing';
							|tr = 'Dahili belge işleme seçimi'");
	Else
		Presentation = NStr("ru = 'Обработки внутреннего документа';
							|vi = 'Internal document processing';
							|en = 'Internal document processing'; fa = 'Internal document processing';
							|it = 'Internal document processing';
							|pl = 'Internal document processing';
							|tr = 'Dahili belge işlemleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessInternalDocumentProcessing", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Обработки входящего документа';
							|vi = 'Incoming document processing';
							|en = 'Incoming document processing'; fa = 'Incoming document processing';
							|it = 'Incoming document processing';
							|pl = 'Incoming document processing';
							|tr = 'Gelen belge işlemleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор обработки входящего документа';
							|vi = 'Select incoming document processing';
							|en = 'Select incoming document processing'; fa = 'Select incoming document processing';
							|it = 'Select incoming document processing';
							|pl = 'Select incoming document processing';
							|tr = 'Gelen belge işleme seçimi'");
	Else
		Presentation = NStr("ru = 'Обработки входящего документа';
							|vi = 'Incoming document processing';
							|en = 'Incoming document processing'; fa = 'Incoming document processing';
							|it = 'Incoming document processing';
							|pl = 'Incoming document processing';
							|tr = 'Gelen belge işlemleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessIncomingDocumentProcessing", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Обработки исходящего документа';
							|vi = 'Outgoing document processing';
							|en = 'Outgoing document processing'; fa = 'Outgoing document processing';
							|it = 'Outgoing document processing';
							|pl = 'Outgoing document processing';
							|tr = 'Giden belge işlemleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор обработки исходящего документа';
							|vi = 'Select outgoing document processing';
							|en = 'Select outgoing document processing'; fa = 'Select outgoing document processing';
							|it = 'Select outgoing document processing';
							|pl = 'Select outgoing document processing';
							|tr = 'Giden belge işleme seçimi'");
	Else
		Presentation = NStr("ru = 'Обработки исходящего документа';
							|vi = 'Outgoing document processing';
							|en = 'Outgoing document processing'; fa = 'Outgoing document processing';
							|it = 'Outgoing document processing';
							|pl = 'Outgoing document processing';
							|tr = 'Giden belge işlemleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessOutgoingDocumentProcessing", Presentation);
	
	TypePresentation = TypesPresentation1.Get(XDTOType);
	
	If ValueIsFilled(TypePresentation) Then
		Return TypePresentation;
	Else
		Return XDTOType;
	EndIf;
	
EndFunction

// Converts the duration of the time interval to a string of the form hour:min.
//
// Parameters:
//   Duration - Number - the duration of the time interval in seconds.
//   ZeroPresentation - String - representation of an interval of zero duration.
//
// Returns:
//   String - representation of the interval in the form of hour:min.
//
Function NumberPerLine(Duration, ZeroPresentation = "'") Export
	
	If Duration = 0 Then
		Return ZeroPresentation;
	EndIf;
	
	Hour = Int(Duration / 3600);
	Min = (Duration - Hour*3600) / 60;
	
	Return Format(Hour, "ND=2; NZ=; NLZ=; NG=") + ":" + Format(Min, "ND=2; NZ=; NLZ=; NG=");
	
EndFunction

// Converts a string of the form hour:min in the duration of the time interval.
//
// Parameters:
//   DurationOfRow - String - representation of the time interval as a string hour:min.
//
// Returns:
//   Number - the duration of the time interval in seconds.
//
Function NumberFromString(DurationOfRow) Export
	
	If Not ValueIsFilled(DurationOfRow) Then
		Return 0;
	EndIf;
	
	Pos = Find(DurationOfRow, ":");
	If Pos = 0 Then
		Return 0;
	EndIf;
	
	Hour = Left(DurationOfRow, Pos-1);
	Min = Mid(DurationOfRow, Pos+1);
	
	Return Number(Hour) * 3600 + Number(Min) * 60;
	
EndFunction

// Checks the string for compliance with the representation of the time interval in the form of hour:min.
//
// Parameters:
//   DurationOfRow - String - the string to check.
//
// Returns:
//   Boolean - True if the passed string corresponds to the form hour:min, and Lie otherwise.
//
Function CheckFormat(DurationOfRow) Export
	
	Pos = Find(DurationOfRow, ":");
	If Pos = 0 Then
		Return False;
	EndIf;
	
	HourRow = Left(DurationOfRow, Pos-1);
	MinRow = Mid(DurationOfRow, Pos+1);
	
	If Not ValueIsFilled(HourRow) Then
		HourRow = "00";
	EndIf;
	If Not ValueIsFilled(MinRow) Then
		MinRow = "00";
	EndIf;
	
	Hour = Number(HourRow);
	Min = Number(MinRow);
	If (Hour >= 24) Or (Min >= 60) Then
		Return False;
	EndIf;
	
	If Hour < 10 Then
		HourRow = "0" + Hour;
	EndIf;
	If Min < 10 Then
		MinRow = "0" + Min;
	EndIf;
	
	DurationOfRow = HourRow + ":" + MinRow;
	
	Return True;
	
EndFunction

// Returns a string representing the project and the project task for the same field.
//
// Parameters:
//   Project - AnyRef, String - link or project view string.
//   TaskOfTheProject - AnyRef, String - link or line of the project task presentation.
//
// Returns:
//   String
//
Function PresentationOfTaskProject(Project, TaskOfTheProject) Export
	
	PresentationOfTaskProject = "";
	
	If ValueIsFilled(TaskOfTheProject) Then
		
		PresentationOfTaskProject = String(Project) + " (" + String(TaskOfTheProject) + ")";
		
	ElsIf ValueIsFilled(Project) Then
		
		PresentationOfTaskProject = String(Project);
		
	EndIf;
	
	Return PresentationOfTaskProject;
	
EndFunction

// Adds a Separator and a value to the String if the String and
// The value being added is not empty. If the Line is empty or the
// value being added is not filled in, then it adds the value being added to the Line.
//
// Parameters:
//   InitialString - String - Modified in the procedure.
//   Separator - String - Separator.
//   ValueToAdd - String - value to add.
//
Procedure AddValueToStringSeparatedBySeparator(InitialString, Separator, ValueToAdd) Export
	
	If IsBlankString(InitialString) Then
		InitialString = String(ValueToAdd);
	ElsIf Not IsBlankString(ValueToAdd) Then
		InitialString = String(InitialString) + Separator + ValueToAdd;
	EndIf;
	
EndProcedure

// Gets a picture of an item from the library according to its role.
//
// Parameters:
//   RoleOfSubject - String - the role of the subject.
//
// Returns:
//   Picture - a picture from the library.
//
Function ImageBySubjectRole(RoleOfSubject) Export
	
	If RoleOfSubject = "Заполняемый" Then //@NON-NLS-1
		Return PictureLib.PopulatedItem16;
	ElsIf RoleOfSubject = "Вспомогательный" Then //@NON-NLS-1
		Return PictureLib.AuxiliaryItem16;
	Else
		Return PictureLib.MainItem16;
	EndIf;
	
EndFunction

// Gets the image number of the item in the collection according to its role.
//
// Parameters:
//   RoleOfSubject - String - the role of the subject.
//
// Returns:
//   Number - the number of the image from the CollectioNaroLipredits
//
Function ImageNumberBySubjectRole(RoleOfSubject) Export
	
	If RoleOfSubject = "Заполняемый" Then //@NON-NLS-1
		Return 5;
	ElsIf RoleOfSubject = "Вспомогательный" Then //@NON-NLS-1
		Return 3;
	Else
		Return 1;
	EndIf;
	
EndFunction

// Checks whether the object type is a reference BEFORE.
//
// Parameters:
//   Type - String - the name of the type XDTO.
//
// Returns:
//   Boolean - true if the type matches the reference TO.
//
Function IsCatalog(Type) Export
	
	Return Type = "DMCorrespondent"
		Or Type = "DMCurrency"
		Or Type = "DMOrganization"
		Or Type = "DMFile"
		Or Type = "DMProject"
		Or Type = "DMSubdivision";
	
EndFunction

// Checks whether the document in the applied sense is the type of the object BEFORE.
//
// Parameters:
//   Type - String - the name of the type XDTO.
//
// Returns:
//   Boolean - true if the type matches the document BEFORE (in the applied sense).
//
Function IsDocument(Type) Export
	
	Return Type = "DMInternalDocument"
		Or Type = "DMIncomingDocument"
		Or Type = "DMOutgoingDocument";
	
EndFunction

// Checks whether the object type is UP to a business process.
//
// Parameters:
//   Type - String - the name of the type XDTO.
//
// Returns:
//   Boolean - true if the type matches the business process BEFORE.
//
Function IsBusinessProcess(Type) Export
	
	// Checking the parent type by means of the factory is too slow.
	Return Type = "DMBusinessProcess"
		Or Type = "DMBusinessProcessAcquaintance"
		Or Type = "DMBusinessProcessApproval"
		Or Type = "DMBusinessProcessApproval_1.2.1.11"
		Or Type = "DMBusinessProcessConfirmation"
		Or Type = "DMBusinessProcessConsideration"
		Or Type = "DMBusinessProcessInvitation"
		Or Type = "DMBusinessProcessIssuesSolution"
		Or Type = "DMBusinessProcessOrder"
		Or Type = "DMBusinessProcessPerformance"
		Or Type = "DMBusinessProcessPerformance_1.2.1.11"
		Or Type = "DMBusinessProcessRegistration"
		Or Type = "DMBusinessProcessIncomingDocumentProcessing"
		Or Type = "DMBusinessProcessInternalDocumentProcessing"
		Or Type = "DMBusinessProcessOutgoingDocumentProcessing"
		Or Type = "DMComplexBusinessProcess";
	
EndFunction

// Checks whether the object type is UP to the task of the business process.
//
// Parameters:
//   Type - String - the name of the type XDTO.
//
// Returns:
//   Boolean - true if the type corresponds to the task BEFORE.
//
Function ThisIsBusinessProcessTask(Type) Export
	
	// Checking the parent type by means of the factory is too slow.
	Return Type = "DMBusinessProcessTask"
		Or Type = "DMBusinessProcessApprovalTaskApproval"
		Or Type = "DMBusinessProcessApprovalTaskCheckup"
		Or Type = "DMBusinessProcessConfirmationTaskCheckup"
		Or Type = "DMBusinessProcessConfirmationTaskConfirmation"
		Or Type = "DMBusinessProcessConsiderationTaskAcquaint"
		Or Type = "DMBusinessProcessInvitationTaskAcquaint"
		Or Type = "DMBusinessProcessInvitationTaskInvitation"
		Or Type = "DMBusinessProcessInvitationTaskNotify"
		Or Type = "DMBusinessProcessIssuesSolutionTaskAnswer"
		Or Type = "DMBusinessProcessIssuesSolutionTaskQuestion"
		Or Type = "DMBusinessProcessOrderTaskCheckup"
		Or Type = "DMBusinessProcessPerfomanceTaskCheckup"
		Or Type = "DMBusinessProcessRegistrationTaskCheckup"
		Or Type = "DMBusinessProcessRegistrationTaskRegistration";
	
EndFunction

// Gets a string representation of the expiration date by the values of the form details.
//
// Parameters:
//   StartDate - Date - Date of commencement of the action.
//   Permanent - Boolean - True if the document is indefinite.
//   EndDate - Date - Expiration date.
//   ExtensionProcedureID - String - the order of extension.
//   ExtensionProcedure - String - description of the renewal procedure.
//
// Returns:
//   String - representation of the expiration date.
//
Function PresentationOfValidityPeriodOfDocument(StartDate, Permanent, EndDate,  ExtensionProcedureID,
		ExtensionProcedure) Export
	
	Result = "";
	If ValueIsFilled(StartDate) Then
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'từ %1';
				|ru = 'с %1';
				|en = 'from %1'; fa = 'from %1';
				|it = 'da %1';
				|pl = 'od %1';
				|tr = 'itibaren %1'"),
			Format(StartDate, "DLF=D"));
	EndIf;
	
	If Permanent = True Then
		Result = StrTemplate(NStr("vi = '%1, không thời hạn';
									|ru = '%1, бессрочный';
									|en = '%1, indefinite'; fa = '%1, indefinite';
									|it = '%1, indeterminato';
									|pl = '%1, bezterminowy';
									|tr = '%1, süresiz'"),
			Result);
	ElsIf ValueIsFilled(EndDate) Then
		Result = StrTemplate(NStr("vi = '%1 đến %2';
									|ru = '%1 по %2';
									|en = '%1 for %2'; fa = '%1 for %2';
									|it = '%1 fino a %2';
									|pl = '%1 do %2';
									|tr = '%1 %2 göre'"),
			Result,
			Format(EndDate, "DLF=D"));
	EndIf;
	
	If ValueIsFilled(ExtensionProcedureID) Then
		If ExtensionProcedureID = "НеПродлевается" Then //@NON-NLS-1
			AddValueToStringSeparatedBySeparator(
				Result,
				Chars.LF,
					NStr("vi = 'Không gia hạn';
						|ru = 'Не продлевается';
						|en = 'Not extended'; fa = 'Not extended';
						|it = 'Non subisce proroga';
						|pl = 'Nie przedłuża się';
						|tr = 'Uzatılamıyor'"));
		ElsIf ExtensionProcedureID = "ДопускаетПродление" Then //@NON-NLS-1
			AddValueToStringSeparatedBySeparator(
				Result,
				Chars.LF,
					NStr("vi = 'Cho phép gia hạn';
						|ru = 'Допускает продление';
						|en = 'Allows extension'; fa = 'Allows extension';
						|it = 'Consente proroga';
						|pl = 'Dopuszcza przedłużenie';
						|tr = 'Uzatılabilir'"));
		Else
			AddValueToStringSeparatedBySeparator(
				Result,
				Chars.LF,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Gia hạn %1';
						|ru = 'Продлевается %1';
						|en = 'Extended %1'; fa = 'Extended %1';
						|it = 'In proroga %1';
						|pl = 'Przedłuża się %1';
						|tr = 'Uzatılıyor %1'"),
					Lower(ExtensionProcedure)));
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the HTML representation of the document to be displayed in the card by the XDTO object.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing integration1sdocumentation with document data.
//
// Returns:
//   String - HTML representation of the document.
//
Function GetDocumentOverview(Form) Export
	
	HTMLTitle =
		"<html>
		|<head>
		|<style type=""text/css"">
		|	body {
		|		overflow:    auto;
		|		margin-top:  6px;
		|		margin-left: 10px;
		|		margin-bottom: 0px;
		|		font-family: Arial, sans-serif;
		|		font-size:   10pt;}
		|	table {
		|		width:       100%;
		|		font-family: Arial, sans-serif;
		|		font-size:   10pt;}
		|	td {vertical-align: top;}
		| 	a:link {
		|		color: #006699; text-decoration: none;}
		|	a:visited {
		|		color: #006699; text-decoration: none;}
		|	a:hover {
		|		color: #006699; text-decoration: underline;}
		|	p {
		|		margin-top: 7px;}
		|</style>
		|<body>";
	
	HTMLEnd = "</body></html>";
	HTMLText = HTMLTitle;
	
	HTMLText = HTMLText + "<table>";
	HTMLText = HTMLText + "<tr>";
	
	If Form.Type = "DMIncomingDocument" Then
		
		HTMLText = HTMLText + "<td width=""40%"" align=center >";
		AddPropsToHtml5(HTMLText, NStr("vi = 'Người gửi:';
										|ru = 'От кого:';
										|en = 'From:'; fa = 'از:';
										|it = 'Da chi:';
										|pl = 'Od kogo:';
										|tr = 'Kimden:'"), "");
		HTMLText = HTMLText + "<p>";
		AddPropsToHtml5(HTMLText, "", Form.Sender,
			Form.SenderID, Form.SenderType);
		
		HTMLText = HTMLText + "<p>";
		HTMLText = HTMLText + Upper(Form.DocumentKind);
		HTMLText = HTMLText + "<p>";
		
		If ValueIsFilled(Form.SenderSNumber) And ValueIsFilled(Form.SenderDate) Then
			AddPropsToHtml5(HTMLText, "",
				Format(Form.SenderDate, "DLF=D") + " № " + Form.SenderSNumber);
		Else
			AddPropsToHtml5(HTMLText, "__________ №__________", "");
		EndIf;
		
		HTMLText = HTMLText + "<p>";
		HTMLText = HTMLText + "</td>";
		HTMLText = HTMLText + "<td>";
		HTMLText = HTMLText + "</td>";
		HTMLText = HTMLText + "<td width=""40%"">";
		
		AddPropsToHtml5(HTMLText, NStr("vi = 'Người nhận:';
										|ru = 'Кому:';
										|en = 'To:'; fa = 'به:';
										|it = 'A chi:';
										|pl = 'To:';
										|tr = 'Kime:'"), "");
		HTMLText = HTMLText + "<p>";
		AddPropsToHtml5(HTMLText, "", Form.Organization);
		If ValueIsFilled(Form.Addressee) Then
			AddPropsToHtml5(HTMLText, "", Form.Addressee);
		EndIf;
		If ValueIsFilled(Form.Department) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Bộ phận:';
											|ru = 'Подразделение:';
											|en = 'Business unit:'; fa = 'واحد تجاری:';
											|it = 'Reparto:';
											|pl = 'Dział:';
											|tr = 'Departman:'"), Form.Department);
		EndIf;
		
		If ValueIsFilled(Form.RegistrationDate) And ValueIsFilled(Form.RegistrationNumber) Then
			
			HTMLText = HTMLText + "<p>";
			AddPropsToHtml5(HTMLText, "",
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Số đăng ký %1 ngày %2';
						|ru = 'Рег. № %1 от %2';
						|en = 'Reg. No. %1 from %2'; fa = 'Reg. No. %1 from %2';
						|it = 'Reg.№ %1 di %2';
						|pl = 'Nr rej. %1 z dn. %2';
						|tr = 'Kayıt.№ %1 %2 den'"),
					Form.RegistrationNumber, Format(Form.RegistrationDate, "DLF=D")));
			
		EndIf;
		
		HTMLText = HTMLText + "</td>";
		HTMLText = HTMLText + "</tr>";
		
		HTMLText = HTMLText + "<tr>";
		HTMLText = HTMLText + "<td colspan=""3"">";
		
		HTMLText = HTMLText + "<p>";
		HTMLText = HTMLText + StringFunctionsClientServer.SubstituteParametersToString(
			"<B>%1</B>",
			Form.Description);
		
		If ValueIsFilled(Form.LongDesc) Or ValueIsFilled(Form.TaskDueDate) Or Form.Sum <> 0 Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		
		If ValueIsFilled(Form.LongDesc) Then
			AddPropsToHtml5(HTMLText, "", StrReplace(Form.LongDesc, Chars.LF, "<br>"));
		EndIf;
		
		If ValueIsFilled(Form.TaskDueDate) Or Form.Sum <> 0 Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		
		If ValueIsFilled(Form.TaskDueDate) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Thời hạn thực hiện:';
											|ru = 'Срок исполнения:';
											|en = 'Due date:'; fa = 'Due date:';
											|it = 'Tempo di esecuzione:';
											|pl = 'Data realizacji:';
											|tr = 'Son tarih:'"),
				Format(Form.TaskDueDate, "DLF=D"),,,
				?(Form.StatePerformanceID <> "Исполнен" And Form.TaskDueDate < BegOfDay(CurrentDate()),
					"B22222",
					"")); //@NON-NLS-3
		EndIf;
		
		HTMLText = HTMLText + "<p>";
		
		If Form.Sum <> 0 Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Số tiền:';
											|ru = 'Сумма:';
											|en = 'Amount:'; fa = 'مبلغ:';
											|it = 'Importo:';
											|pl = 'Amount:';
											|tr = 'Tutar:'"),
				Format(Form.Sum, "NFD=2; NZ=0") + " " + Form.Currency);
		EndIf;
		
		AddAdditionalProperties(HTMLText, Form);
		
		HTMLText = HTMLText + "</td></tr>";
		
		If ValueIsFilled(Form.SignedBy) Then
			
			HTMLText = HTMLText + "<tr>";
			HTMLText = HTMLText + "<td colspan=""3"">";
			
			HTMLText = HTMLText + "<p>";
			AddPropsToHtml5(HTMLText, NStr("vi = 'Người ký:';
											|ru = 'Подписал:';
											|en = 'Signed:'; fa = 'Signed:';
											|it = 'Firmato:';
											|pl = 'Signed:';
											|tr = 'İmzaladı:'"), Form.SignedBy);
			
			HTMLText = HTMLText + "</td></tr>";
			
		EndIf;
		
		HTMLText = HTMLText + "<tr>";
		HTMLText = HTMLText + "<td colspan=""2"">";
		If ValueIsFilled(Form.EmployeeResponsible)
			Or ValueIsFilled(Form.Department) Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		If ValueIsFilled(Form.EmployeeResponsible) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Người chịu trách nhiệm:';
											|ru = 'Ответственный:';
											|en = 'Responsible person:'; fa = 'Responsible person:';
											|it = 'Responsabile:';
											|pl = 'Osoba odpowiedzilana:';
											|tr = 'Sorumlu:'"), Form.EmployeeResponsible);
		EndIf;
		HTMLText = HTMLText + "</tr>";
		
	ElsIf Form.Type = "DMInternalDocument" Then
		
		HTMLText = HTMLText + "<td colspan=""2"" align=""center"">";
		
		HTMLText = HTMLText + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 số %2 ngày %3';
				|ru = '%1 № %2 от %3';
				|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
				|it = '%1 № %2 dal %3';
				|pl = '%1 nr %2 z dnia %3.';
				|tr = '%1 № %2 %3ten'"),
			Upper(Form.DocumentKind),
			?(ValueIsFilled(Form.RegistrationNumber), Form.RegistrationNumber, "_____"),
			?(ValueIsFilled(Form.RegistrationDate), Format(Form.RegistrationDate, "DLF=D"), "_____"));
		
		HTMLText = HTMLText + "</td></tr>";
		
		HTMLText = HTMLText + "<tr>";
		HTMLText = HTMLText + "<td colspan=""2"" align=""center"" >";
		
		HTMLText = HTMLText + "<p>";
		HTMLText = HTMLText + StringFunctionsClientServer.SubstituteParametersToString(
			"<B>%1</B>",
			Form.Description);
		HTMLText = HTMLText + "</td></tr>";
		
		HTMLText = HTMLText + "<tr>";
		HTMLText = HTMLText + "<td colspan=""2"" >";
		
		If ValueIsFilled(Form.LongDesc) Or ValueIsFilled(Form.TaskDueDate) Or Form.Sum <> 0 Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		
		If ValueIsFilled(Form.LongDesc) Then
			AddPropsToHtml5(HTMLText, "", StrReplace(Form.LongDesc, Chars.LF, "<br>"));
		EndIf;
			
		If ValueIsFilled(Form.TaskDueDate) Or Form.Sum <> 0 Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		
		If ValueIsFilled(Form.TaskDueDate) Then
			AddPropsToHtml5(
				HTMLText,
				NStr("vi = 'Thời hạn thực hiện:';
					|ru = 'Срок исполнения:';
					|en = 'Due date:'; fa = 'Due date:';
					|it = 'Tempo di esecuzione:';
					|pl = 'Data realizacji:';
					|tr = 'Son tarih:'"),
				Format(Form.TaskDueDate, "DLF=D"),,,
				?(Form.StatePerformanceID <> "Исполнен" And Form.TaskDueDate < BegOfDay(CurrentDate()),
					"B22222",
					"")); //@NON-NLS-3
		EndIf;
		
		If Form.Sum <> 0 Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Số tiền:';
											|ru = 'Сумма:';
											|en = 'Amount:'; fa = 'مبلغ:';
											|it = 'Importo:';
											|pl = 'Amount:';
											|tr = 'Tutar:'"),
				Format(Form.Sum, "NFD=2; NZ=0") + " " + Form.Currency);
			
			If Form.FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.InternalDocument"
					And Form.ConsiderVAT Then
				AddPropsToHtml5(HTMLText, NStr("vi = 'Số tiền thuế GTGT:';
												|ru = 'Сумма НДС:';
												|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
												|it = 'Importo IVA:';
												|pl = 'Wartość VAT';
												|tr = 'KDV tutarı:'"),
					Format(Form.VATAmount, "NFD=2; NZ=0") + " " + Form.Currency);
			EndIf;
			
			If Form.KeepRecordsOfGoodsAndServices And Form.Goods.Count() > 0 Then
				NumberOfRows = Form.Goods.Count();
				AddPropsToHtml5(HTMLText, NStr("vi = 'Hàng hóa và dịch vụ:';
												|ru = 'Товары и услуги:';
												|en = 'Goods and services:'; fa = 'Goods and services:';
												|it = 'Articoli e servizi:';
												|pl = 'Towary i usługi:';
												|tr = 'Ürünler ve hizmetler:'"),
					Format(NumberOfRows, "NG=") + " "
						+ UsersInternalClientServer.IntegerSubject(
							NumberOfRows,
							"",
							NStr("vi = 'mặt hàng,mặt hàng,mặt hàng,,,,,,0';
								|ru = 'позиция,позиции,позиций,,,,,,0';
								|en = 'position,positions,positions,,,,,,0'; fa = 'position,positions,positions,,,,,,0';
								|it = 'posizione, posizioni,,,,,,0';
								|pl = 'position,positions,positions,,,,,,0';
								|tr = 'pozisyon, pozisyonlar, pozisyonların,,,,,,0'")));
			EndIf;
			
			If Form.FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.InternalDocument"
					And Form.KeepRecordsOfCFItem Then
				CFItems = Form.CFItems;
				NumberOfArticles = CFItems.Count();
				If NumberOfArticles = 1 Then
					AddPropsToHtml5(HTMLText, NStr("vi = 'Dạng lưu chuyển tiền tệ:';
													|ru = 'Статья ДДС:';
													|en = 'Cash flow item:'; fa = 'قلم جریان وجوه نقد:';
													|it = 'Voce del flusso di cassa:';
													|pl = 'Pozycja ruchu środków pieniężnych:';
													|tr = 'NA öğesi:'"),
						CFItems[0].CFItem);
				ElsIf NumberOfArticles > 1 Then
					AddCaptionToHtml5(HTMLText, NStr("vi = 'Dạng lưu chuyển tiền tệ:';
													|ru = 'Статьи ДДС:';
													|en = 'Cash flow items:'; fa = 'اقلام جریان وجوه نقد:';
													|it = 'Voci del flusso di cassa:';
													|pl = 'Pozycje ruchu środków pieniężnych:';
													|tr = 'Nakit akış tablosu kalemleri:'"));
					Separator = "";
					For Each String In CFItems Do
						HTMLText = HTMLText + Separator;
						AddValueToHtml5(HTMLText, String.CFItem, "");
						Separator = "; ";
					EndDo;
					HTMLText = HTMLText + "<br>";
				EndIf;
			EndIf;
		EndIf;
		
		AddExpirationPresentation(HTMLText, Form);
		AddAdditionalProperties(HTMLText, Form);
		
		HTMLText = HTMLText + "</td></tr>";
		
		If Form.KeepRecordsOfCounterparties
				And (ValueIsFilled(Form.Counterparty)
					Or Form.Counterparties.Count()
					Or Form.IsRequestForPayment) Then
			HTMLText = HTMLText + "<tr>";
			
			HTMLText = HTMLText + "<td width=""70%"">";
			HTMLText = HTMLText + "<p>";
			AddPropsToHtml5(HTMLText, NStr("vi = 'Doanh nghiệp của chúng ta:';
											|ru = 'Наша организация:';
											|en = 'Our company:'; fa = 'Our company:';
											|it = 'La nostra azienda:';
											|pl = 'Nasza firma:';
											|tr = 'İş yerimiz:'"), "");
			HTMLText = HTMLText + "<p>";
			AddPropsToHtml5(HTMLText, "", Form.Organization);
			
			If ValueIsFilled(Form.SignedBy) Then
				AddPropsToHtml5(HTMLText, NStr("vi = 'Người ký:';
												|ru = 'Подписал:';
												|en = 'Signed:'; fa = 'Signed:';
												|it = 'Firmato:';
												|pl = 'Signed:';
												|tr = 'İmzaladı:'"), Form.SignedBy);
			EndIf;
			HTMLText = HTMLText + "</td>";
			
			UseTermCorrespondents = False;
			
			If Not Form.MultipleCounterparties Then
				If ValueIsFilled(Form.Counterparty) Then
					HTMLText = HTMLText + "<td>";
					HTMLText = HTMLText + "<p>";
					
					If UseTermCorrespondents Then
						AddPropsToHtml5(HTMLText, NStr("vi = 'Cơ sở thông tin trao đổi:';
														|ru = 'Корреспондент:';
														|en = 'Correspondent:'; fa = 'Correspondent:';
														|it = 'Corrispondente:';
														|pl = 'Correspondent:';
														|tr = 'Muhabir:'"), "");
					Else
						AddPropsToHtml5(HTMLText, NStr("vi = 'Đối tác:';
														|ru = 'Контрагент:';
														|en = 'Counterparty:'; fa = 'طرف حساب:';
														|it = 'Controparte:';
														|pl = 'Counterparty:';
														|tr = 'Cari hesap:'"), "");
					EndIf;
					
					HTMLText = HTMLText + "<p>";
					
					AddPropsToHtml5(HTMLText, "",
						Form.Counterparty,
						Form.CounterpartyID,
						Form.CounterpartyType);
					
					If ValueIsFilled(Form.SignedFromCounterparty) Then
						AddPropsToHtml5(HTMLText, NStr("vi = 'Người ký:';
														|ru = 'Подписал:';
														|en = 'Signed:'; fa = 'Signed:';
														|it = 'Firmato:';
														|pl = 'Signed:';
														|tr = 'İmzaladı:'"), Form.SignedFromCounterparty);
					EndIf;
					
					If ValueIsFilled(Form.ContactPerson) Then
						AddPropsToHtml5(HTMLText, NStr("vi = 'Liên hệ:';
														|ru = 'Контакт:';
														|en = 'Contact:'; fa = 'تماس:';
														|it = 'Contatti:';
														|pl = 'Contact:';
														|tr = 'İletişim:'"), Form.ContactPerson);
					EndIf;
					
					HTMLText = HTMLText + "</td></tr>";
				EndIf;
			Else
				HTMLText = HTMLText + "<td>";
				HTMLText = HTMLText + "<p>";
				
				Count = 0;
				For Each CounterpartyLine In Form.Counterparties Do
					If ValueIsFilled(CounterpartyLine.CounterpartyID) Then
						Count = Count + 1;
					EndIf;
				EndDo;
				
				If Count = 1 Then
					AddPropsToHtml5(HTMLText, NStr("vi = 'Đối tác:';
													|ru = 'Контрагент:';
													|en = 'Counterparty:'; fa = 'طرف حساب:';
													|it = 'Controparte:';
													|pl = 'Counterparty:';
													|tr = 'Cari hesap:'"), "");
				Else
					AddPropsToHtml5(HTMLText, NStr("vi = 'Đối tác:';
													|ru = 'Контрагенты:';
													|en = 'Counterparties:'; fa = 'Counterparties:';
													|it = 'Controparti:';
													|pl = 'Counterparties:';
													|tr = 'Cari hesaplar:'"), "");
				EndIf;
				
				HTMLText = HTMLText + "<p>";
				
				For Each CounterpartyLine In Form.Counterparties Do
					If ValueIsFilled(CounterpartyLine.CounterpartyID) Then
						AddPropsToHtml5(HTMLText, "",
							CounterpartyLine.Counterparty,
							CounterpartyLine.CounterpartyID,
							CounterpartyLine.CounterpartyType);
					EndIf;
					
					If ValueIsFilled(CounterpartyLine.SignedFromCounterparty) Then
						AddPropsToHtml5(HTMLText,
							NStr("vi = 'Người ký:';
								|ru = 'Подписал:';
								|en = 'Signed:'; fa = 'Signed:';
								|it = 'Firmato:';
								|pl = 'Signed:';
								|tr = 'İmzaladı:'"),
							CounterpartyLine.SignedFromCounterparty);
					EndIf;
					
					If ValueIsFilled(CounterpartyLine.ContactPerson) Then
						AddPropsToHtml5(HTMLText,
							NStr("vi = 'Liên hệ:';
								|ru = 'Контакт:';
								|en = 'Contact:'; fa = 'تماس:';
								|it = 'Contatti:';
								|pl = 'Contact:';
								|tr = 'İletişim:'"),
							CounterpartyLine.ContactPerson);
					EndIf;
					
					HTMLText = HTMLText + "<p>";
				EndDo;
				
				// Removing extra padding
				HTMLText = Left(HTMLText, StrLen(HTMLText) - 3);
			EndIf;
			HTMLText = HTMLText + "</tr>";
		Else
			AddSides(HTMLText, Form);
		EndIf;
		
		HTMLText = HTMLText + "<tr>";
		HTMLText = HTMLText + "<td colspan=""2"">";
		
		If ValueIsFilled(Form.EmployeeResponsible)
				Or ValueIsFilled(Form.Department)
				Or ValueIsFilled(Form.Prepared) Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		If ValueIsFilled(Form.Prepared) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Người soạn:';
											|ru = 'Подготовил:';
											|en = 'Prepared:'; fa = 'Prepared:';
											|it = 'Preparato:';
											|pl = 'Prepared:';
											|tr = 'Hazırlayan:'"), Form.Prepared);
		EndIf;
		If ValueIsFilled(Form.Department) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Bộ phận:';
											|ru = 'Подразделение:';
											|en = 'Business unit:'; fa = 'واحد تجاری:';
											|it = 'Reparto:';
											|pl = 'Dział:';
											|tr = 'Departman:'"), Form.Department);
		EndIf;
		If ValueIsFilled(Form.EmployeeResponsible) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Người chịu trách nhiệm:';
											|ru = 'Ответственный:';
											|en = 'Responsible person:'; fa = 'Responsible person:';
											|it = 'Responsabile:';
											|pl = 'Osoba odpowiedzilana:';
											|tr = 'Sorumlu:'"), Form.EmployeeResponsible);
		EndIf;
		HTMLText = HTMLText + "</tr>";
		
	ElsIf Form.Type = "DMOutgoingDocument" Then
		
		HTMLText = HTMLText + "<td width=""40%"" align=center >";
		AddPropsToHtml5(HTMLText, NStr("vi = 'Người gửi:';
										|ru = 'От кого:';
										|en = 'From:'; fa = 'از:';
										|it = 'Da chi:';
										|pl = 'Od kogo:';
										|tr = 'Kimden:'"), "");
		HTMLText = HTMLText + "<p>";
		AddPropsToHtml5(HTMLText, "", Form.Organization);
		
		HTMLText = HTMLText + "<p>";
		HTMLText = HTMLText + Upper(Form.DocumentKind);
		HTMLText = HTMLText + "<p>";
		
		If ValueIsFilled(Form.RegistrationDate) And ValueIsFilled(Form.RegistrationNumber) Then
			
			AddPropsToHtml5(HTMLText, "",
				Format(Form.RegistrationDate, "DLF=D") + " № " +  Form.RegistrationNumber);
			
		Else
			
			AddPropsToHtml5(HTMLText, "__________ №__________", "");
			
		EndIf;
		
		HTMLText = HTMLText + "<p>";
		HTMLText = HTMLText + "</td>";
		HTMLText = HTMLText + "<td>";
		HTMLText = HTMLText + "</td>";
		HTMLText = HTMLText + "<td width=""40%"">";
		
		AddPropsToHtml5(HTMLText, NStr("vi = 'Người nhận:';
										|ru = 'Кому:';
										|en = 'To:'; fa = 'به:';
										|it = 'A chi:';
										|pl = 'To:';
										|tr = 'Kime:'"), "");
		HTMLText = HTMLText + "<p>";
		AddPropsToHtml5(HTMLText, "", Form.Recipient,
			Form.RecipientID, Form.RecipientType);
		If ValueIsFilled(Form.Addressee) Then
			AddPropsToHtml5(HTMLText, "", Form.Addressee);
		EndIf;
		
		HTMLText = HTMLText + "</td>";
		HTMLText = HTMLText + "</tr>";
		
		HTMLText = HTMLText + "<tr>";
		HTMLText = HTMLText + "<td colspan=""3"">";
		
		HTMLText = HTMLText + "<p>";
		HTMLText = HTMLText + StringFunctionsClientServer.SubstituteParametersToString(
			"<B>%1</B>",
			Form.Description);
		
		If ValueIsFilled(Form.LongDesc) Or ValueIsFilled(Form.TaskDueDate) Or Form.Sum <> 0 Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		
		If ValueIsFilled(Form.LongDesc) Then
			AddPropsToHtml5(HTMLText, "",
				StrReplace(Form.LongDesc, Chars.LF, "<br>"));
		EndIf;
		
		If ValueIsFilled(Form.TaskDueDate) Or Form.Sum <> 0 Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		
		If ValueIsFilled(Form.TaskDueDate) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Thời hạn phản hồi:';
											|ru = 'Срок ответа:';
											|en = 'Period for response:'; fa = 'Period for response:';
											|it = 'Periodo di risposta:';
											|pl = 'Termin odpowiedzi:';
											|tr = 'Yanıt süresi:'"),
				Format(Form.TaskDueDate, "DLF=D"));
		EndIf;
		
		If Form.Sum <> 0 Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Số tiền:';
											|ru = 'Сумма:';
											|en = 'Amount:'; fa = 'مبلغ:';
											|it = 'Importo:';
											|pl = 'Amount:';
											|tr = 'Tutar:'"),
				Format(Form.Sum, "NFD=2; NZ=0") + " " + Form.Currency);
		EndIf;
		
		AddAdditionalProperties(HTMLText, Form);
		
		HTMLText = HTMLText + "</td></tr>";
		
		HTMLText = HTMLText + "<tr>";
		HTMLText = HTMLText + "<td colspan=""3"">";
		If ValueIsFilled(Form.SignedBy) Or ValueIsFilled(Form.Prepared)
				Or ValueIsFilled(Form.Department) Then
			
			If ValueIsFilled(Form.TaskDueDate) Or Form.Sum <> 0 Then
				HTMLText = HTMLText + "<p>";
			EndIf;
			
			If ValueIsFilled(Form.SignedBy) Then
				AddPropsToHtml5(HTMLText, NStr("vi = 'Người ký:';
												|ru = 'Подписал:';
												|en = 'Signed:'; fa = 'Signed:';
												|it = 'Firmato:';
												|pl = 'Signed:';
												|tr = 'İmzaladı:'"), Form.SignedBy);
			EndIf;
			If ValueIsFilled(Form.Prepared) Then
				AddPropsToHtml5(HTMLText, NStr("vi = 'Người soạn:';
												|ru = 'Подготовил:';
												|en = 'Prepared:'; fa = 'Prepared:';
												|it = 'Preparato:';
												|pl = 'Prepared:';
												|tr = 'Hazırlayan:'"), Form.Prepared);
			EndIf;
			If ValueIsFilled(Form.Department) Then
				AddPropsToHtml5(HTMLText, NStr("vi = 'Bộ phận:';
												|ru = 'Подразделение:';
												|en = 'Business unit:'; fa = 'واحد تجاری:';
												|it = 'Reparto:';
												|pl = 'Dział:';
												|tr = 'Departman:'"), Form.Department);
			EndIf;
			
		EndIf;
		HTMLText = HTMLText + "</td></tr>";
		
		HTMLText = HTMLText + "<tr>";
		HTMLText = HTMLText + "<td colspan=""2"">";
		If ValueIsFilled(Form.EmployeeResponsible) Then
			HTMLText = HTMLText + "<p>";
		EndIf;
		If ValueIsFilled(Form.EmployeeResponsible) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Người chịu trách nhiệm:';
											|ru = 'Ответственный:';
											|en = 'Responsible person:'; fa = 'Responsible person:';
											|it = 'Responsabile:';
											|pl = 'Osoba odpowiedzilana:';
											|tr = 'Sorumlu:'"), Form.EmployeeResponsible);
		EndIf;
		
		HTMLText = HTMLText + "</tr>";
		
	EndIf;
	
	HTMLText = HTMLText + "<br>";
	
	HTMLText = HTMLText + "<tr>";
	HTMLText = HTMLText + "<td colspan=""3"">";
	
	HTMLText = HTMLText + "<p>";
	
	If Form.Type = "DMInternalDocument" And ValueIsFilled(Form.Folder) Then
		AddPropsToHtml5(HTMLText, NStr("vi = 'Thư mục:';
										|ru = 'Папка:';
										|en = 'Folder:'; fa = 'Folder:';
										|it = 'Cartella:';
										|pl = 'Folder:';
										|tr = 'Klasör:'"), Form.Folder);
	EndIf;
	If ValueIsFilled(Form.AccessBar) Then
		AddPropsToHtml5(HTMLText, NStr("vi = 'Độ mật:';
										|ru = 'Гриф:';
										|en = 'Label:'; fa = 'Label:';
										|it = 'Dicitura:';
										|pl = 'Label:';
										|tr = 'Etiket:'"), Form.AccessBar);
	EndIf;
	If ValueIsFilled(Form.QuestionOfActivity) Then
		AddPropsToHtml5(HTMLText, NStr("vi = 'Vấn đề:';
										|ru = 'Вопрос:';
										|en = 'Question:'; fa = 'Question:';
										|it = 'Domanda:';
										|pl = 'Question:';
										|tr = 'Soru:'"), Form.QuestionOfActivity);
	EndIf;
	If ValueIsFilled(Form.Project) Then
		AddPropsToHtml5(HTMLText, NStr("vi = 'Dự án:';
										|ru = 'Проект:';
										|en = 'Project:'; fa = 'Project:';
										|it = 'Progetto:';
										|pl = 'Project:';
										|tr = 'Proje:'"), Form.Project);
	EndIf;
	
	AddStatePresentation(HTMLText, Form);
	
	If ValueIsFilled(Form.Comment) Then
		AddPropsToHtml5(HTMLText, NStr("vi = 'Ghi chú:';
										|ru = 'Комментарий:';
										|en = 'Comment:'; fa = 'توضیحات:';
										|it = 'Commento:';
										|pl = 'Comment:';
										|tr = 'Yorum:'"), Form.Comment);
	EndIf;
	
	HTMLText = HTMLText + "</td></tr>";
	
	HTMLText = HTMLText + "</table>";
	
	HTMLText = HTMLText + HTMLEnd;
	
	Return HTMLText;
	
EndFunction

// Forms a textual representation of the composition of the document.
//
// Parameters:
//   Form - ClientApplicationForm -  the form of processing integration1sdocumentation with document data.
//
// Returns:
//   String - a textual representation of the composition of the document.
//
Function GetDocumentCompositionString(Form) Export
	
	LineComposition = ?(Form.SheetQuantity > 0, StrTemplate(
		NStr("vi = 'tờ %1,';
			|ru = 'листов %1,';
			|en = 'pages %1,'; fa = 'pages %1,';
			|it = 'schede %1,';
			|pl = 'arkuszy %1,';
			|tr = '%1sayfalar,'") + " ", Form.SheetQuantity), "");
			
	LineComposition = LineComposition + ?(Form.NumberOfApplications > 0, StrTemplate(
		NStr("vi = 'đính kèm %1,';
			|ru = 'приложений %1,';
			|en = 'appendices %1,'; fa = 'appendices %1,';
			|it = 'applicazioni %1,';
			|pl = 'załączników %1,';
			|tr = '%1uygulama,'") + " ", Form.NumberOfApplications), "");
			
	LineComposition = LineComposition + ?(Form.SheetsInApplications > 0, StrTemplate(
		NStr("vi = 'tờ trong phụ lục %1,';
			|ru = 'листов в приложениях %1,';
			|en = 'pages in appendices %1,'; fa = 'pages in appendices %1,';
			|it = 'schede nelle applicazioni %1,';
			|pl = 'arkuszy w załącznikach %1,';
			|tr = '%1 uygulamalarındaki sayfalar,'") + " ", Form.SheetsInApplications), "");
			
	LineComposition = LineComposition + ?(Form.Copies > 0, StrTemplate(
		NStr("vi = 'bản in %1,';
			|ru = 'экземпляров %1,';
			|en = 'copies %1,'; fa = 'copies %1,';
			|it = 'copie %1,';
			|pl = 'egzemplarzy %1,';
			|tr = '%1 kopyaları,'") + " ", Form.Copies), "");
			
	LineComposition = Upper(Left(LineComposition,1)) + Right(LineComposition, StrLen(LineComposition) - 1);
	
	If Right(LineComposition, 2) = ", " Then
		LineComposition = Left(LineComposition, StrLen(LineComposition) - 2);
	EndIf;
	
	Return LineComposition;
	
EndFunction

// String description of the date difference in days, taking into account declinations
//
// Parameters:
//   Date1 - Date - the first date.
//   Date2 - Date - the second date.
//   UseDateAndTimeInTaskDeadlines - Boolean - indicates whether the date is used in the task deadlines.
//
// Returns:
//   String - a textual representation of the date difference.
//
Function DateDifferenceInDays(Date1, Date2, UseDateAndTimeInTaskDeadlines = True) Export
	
	If UseDateAndTimeInTaskDeadlines Then
		NumberOfHours = Round((Date1 - Date2) / (60*60));
		NumberOfDays = Round(NumberOfHours / 24);
		NumberOfHours = NumberOfHours - NumberOfDays * 24;
	Else
		NumberOfHours = 0;
		NumberOfDays = (BegOfDay(Date1) - BegOfDay(Date2)) / (60*60*24);
	EndIf;
		
	If NumberOfHours < 0 Then
		NumberOfDays = NumberOfDays - 1;
		NumberOfHours = NumberOfHours + 24;
	EndIf;
	SignatureOfDays = GetSignatureDays(NumberOfDays);
	SignatureOfWatch = GetWatchSignature(NumberOfHours);
	
	If UseDateAndTimeInTaskDeadlines Then
		If NumberOfDays > 0 And NumberOfHours > 0 Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 %2 và %3 %4';
					|ru = '%1 %2 и %3 %4';
					|en = '%1 %2 and %3 %4'; fa = '%1 %2 and %3 %4';
					|it = '%1 %2 e %3 %4';
					|pl = '%1 %2 i %3 %4';
					|tr = '%1 %2 ve %3 %4'"),
				String(NumberOfDays),
				SignatureOfDays,
				String(NumberOfHours),
				SignatureOfWatch);
		ElsIf NumberOfDays > 0 Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				"%1 %2",
				String(NumberOfDays),
				SignatureOfDays);
		ElsIf NumberOfHours > 0 Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				"%1 %2",
				String(NumberOfHours),
				SignatureOfWatch);
		Else
			Return NStr("vi = 'Ít hơn 1 giờ';
						|ru = 'Менее 1 часа';
						|en = 'Less than 1 hour'; fa = 'Less than 1 hour';
						|it = 'Meno di 1 ora';
						|pl = 'Mniej 1 godziny';
						|tr = '1 saatten az'");
		EndIf;
	Else
		If NumberOfDays > 0 Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				"%1 %2",
				String(NumberOfDays),
				SignatureOfDays);
		Else
			Return NStr("vi = 'Ít hơn 1 ngày';
						|ru = 'Менее 1 дня';
						|en = 'Less than 1 day'; fa = 'Less than 1 day';
						|it = 'Meno di 1 giorno';
						|pl = 'Mniej 1 dnia';
						|tr = '1 günden az'");
		EndIf;
	EndIf;
	
EndFunction

#EndRegion

#Region Private

// Adds a caption to the HTML representation of the object.
//
// Parameters:
//   HTMLText - String - the text being processed.
//   Signature - String - the signature text.
//
Procedure AddCaptionToHtml5(HTMLText, Signature)
	
	If ValueIsFilled(Signature) Then
		HTMLText = HTMLText + "<FONT color=#413003>";
		HTMLText = HTMLText + Signature + " ";
		HTMLText = HTMLText + "</FONT>";
	EndIf;
	
EndProcedure

// Adds a value to the HTML representation, formatting it as a link if necessary.
//
// Parameters:
//   HTMLText - String - the text being processed.
//   Presentation - String - value to add.
//   Id - String - id of the value to be added.
//   Type - String - the type of value to be added.
//
Procedure AddValueToHtml5(HTMLText, Presentation, Id = Undefined, Type = Undefined, Color = "")
	
	If ValueIsFilled(Id) And ValueIsFilled(Type) Then
		HTMLText = HTMLText + StringFunctionsClientServer.SubstituteParametersToString(
			"<A href=dmil:%1>%2</A>",
			Type + ":" + Id,
			Presentation);
	Else
		If ValueIsFilled(Color) Then
			HTMLText = HTMLText + "<FONT color=#"+Color+">";
			HTMLText = HTMLText + Presentation;
			HTMLText = HTMLText + "</FONT>";
		Else
			HTMLText = HTMLText + Presentation;
		EndIf;
	EndIf;
	
EndProcedure

// Adds the props (signature and value) to the HTML representation of the object
//
// Parameters:
//   HTMLText - String - the text being processed.
//   Signature - String - signature of the props.
//   Presentation - String - value to add.
//   Id - String - id of the value to be added.
//   Type - String - the type of value to be added.
//
Procedure AddPropsToHtml5(HTMLText, Signature, Presentation, Id = Undefined, Type = Undefined,
		Color = "")
	
	AddCaptionToHtml5(HTMLText, Signature);
	AddValueToHtml5(HTMLText, Presentation, Id, Type, Color);
	HTMLText = HTMLText + "<br>";
	
EndProcedure

// Adds a representation of the document states to its HTML representation.
//
// Parameters:
//   HTMLText - String - the text being processed.
//   Form - ClientApplicationForm - the form of the document.
//
Procedure AddStatePresentation(HTMLText, Form)
	
	ArrayPresentation_ = New Array;
	Sequence = New Structure;
	Sequence.Insert("StateApproval");
	Sequence.Insert("StateConfirmation");
	Sequence.Insert("StateRegistration");
	Sequence.Insert("StateReviewal");
	If Form.Type = "DMInternalDocument" Then
		Sequence.Insert("StateSigning");
	EndIf;
	Sequence.Insert("StatePerformance");
	For Each TypeOfState In Sequence Do
		State = Form[TypeOfState.Key];
		If ValueIsFilled(State) Then
			ArrayPresentation_.Add(State);
		EndIf;
	EndDo;
	
	NumberOfStates = ArrayPresentation_.Count();
	If NumberOfStates > 1 Then
		For IndexOf = 0 To NumberOfStates - 1 Do
			If ArrayPresentation_[IndexOf] = "Project" Then
				ArrayPresentation_.Delete(IndexOf);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Presentation = StrConcat(ArrayPresentation_, ", ");
	
	// Old versions of the service give only one state.
	Presentation = ?(Presentation = "", Form.State, Presentation);
	If Presentation = "" Then
		Return;
	EndIf;
	
	AddCaptionToHtml5(HTMLText, NStr("vi = 'Trạng thái:';
									|ru = 'Состояние:';
									|en = 'State:'; fa = 'وضعیت:';
									|it = 'Stato:';
									|pl = 'State:';
									|tr = 'Durum:'"));
	HTMLText = HTMLText
		+ ?(Form.CorpFunctionalityIsAvailable,
			StringFunctionsClientServer.SubstituteParametersToString(
				"<A href=dmil:%1:%2:%3>%4</A>",
				Form.Type, Form.ID, "status",
				Presentation),
			Presentation)
		+ "<br>";
	
EndProcedure

// Adds a document expiration representation to its HTML representation.
//
// Parameters:
//   HTMLText - String - the text being processed.
//   Form - ClientApplicationForm - the form of the document.
//
Procedure AddExpirationPresentation(HTMLText, Form)
	
	Presentation = PresentationOfValidityPeriodOfDocument(
		Form.ValidityStartDate, Form.Permanent, Form.ValidityEndDate,
		Form.ExtensionProcedureID, Form.ExtensionProcedure);
	If Presentation = "" Then
		Return;
	EndIf;
		
	AddCaptionToHtml5(HTMLText, NStr("vi = 'Thời hạn hiệu lực:';
									|ru = 'Срок действия:';
									|en = 'Validity period:'; fa = 'Validity period:';
									|it = 'Validità:';
									|pl = 'Termin ważności:';
									|tr = 'Geçerlilik tarihi:'"));
	HTMLText = HTMLText + StringFunctionsClientServer.SubstituteParametersToString(
		"<A href=dmil:%1:%2:%3>%4</A>",
		Form.Type, Form.ID, "term",
		Presentation)
		+ "<br>";
		
EndProcedure

// Adds additional document properties to its HTML representation.
//
// Parameters:
//   HTMLText - String - the text being processed.
//   Form - ClientApplicationForm - the form of the document.
//
Procedure AddAdditionalProperties(HTMLText, Form)
	
	For Each PropertyRow In Form.Properties Do
		If ValueIsFilled(PropertyRow.Value) Then
			AddPropsToHtml5(HTMLText,
				PropertyRow.Property + ":",
				PropertyRow.Value);
		EndIf;
	EndDo;
	
EndProcedure

// Adds the sides of the document to its HTML representation.
//
// Parameters:
//   HTMLText - String - the text being processed.
//   Form - ClientApplicationForm - the form of the document.
//
Procedure AddSides(HTMLText, Form)
	
	If Not Form.KeepRecordsOfParties And Form.Parties.Count() = 0 Then
		Return;
	EndIf;
	
	OrganizationRows = New Array;
	CounterpartiesLines = New Array;
	
	For Each TableRow In Form.Parties Do
		If TableRow.PartyType = "DMOrganization"
				Or IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(
					TableRow.PartyType) = "DMOrganization" Then
			OrganizationRows.Add(TableRow);
		Else
			CounterpartiesLines.Add(TableRow);
		EndIf;
	EndDo;
	
	If Not CounterpartiesLines.Count() Then
		LastItemIndex = OrganizationRows.UBound();
		For Counter = 1 To LastItemIndex Do
			CounterpartiesLines.Add(OrganizationRows[Counter]);
		EndDo;
		For Counter = 0 To LastItemIndex - 1 Do
			OrganizationRows.Delete(LastItemIndex - Counter);
		EndDo;
	EndIf;
	
	HTMLText = HTMLText + "<tr>";
	HTMLText = HTMLText + "<td colspan=""2"" align=""center"">";
	HTMLText = HTMLText + "<p>";
	AddPropsToHtml5(HTMLText, NStr("vi = 'CÁC BÊN';
									|ru = 'СТОРОНЫ';
									|en = 'PARTIES'; fa = 'PARTIES';
									|it = 'PARTI';
									|pl = 'PARTIES';
									|tr = 'Taraflar'"), "");
	HTMLText = HTMLText + "</td></tr>";

	HTMLText = HTMLText + "<tr>";
	HTMLText = HTMLText + "<td width=""70%"">";
	
	AddSideDescription(HTMLText, OrganizationRows);
	AddSideDescription(HTMLText, CounterpartiesLines);
	
	HTMLText = HTMLText + "</td></tr>";
	
EndProcedure

// Adds the sides of the document to its HTML representation.
//
// Parameters:
//   HTMLText - String - the text being processed.
//   Party - Array of ValueTableRow - rows of the "Sides" table from the internal document form.
//
Procedure AddSideDescription(HTMLText, Party)
	
	For Each DescriptionOfParty In Party Do
		
		If ValueIsFilled(DescriptionOfParty.Description) Then
			AddPropsToHtml5(HTMLText, TrimAll(DescriptionOfParty.Description) + ":", "");
		EndIf;
		AddPropsToHtml5(HTMLText, "", DescriptionOfParty.Party);
		
		If DescriptionOfParty.Signed Then
			Signatory = DescriptionOfParty.SignedBy;
			AddPropsToHtml5(HTMLText, NStr("vi = 'Người ký:';
											|ru = 'Подписал:';
											|en = 'Signed:'; fa = 'Signed:';
											|it = 'Firmato:';
											|pl = 'Signed:';
											|tr = 'İmzaladı:'"), Signatory);
		EndIf;
		
		If ValueIsFilled(DescriptionOfParty.ContactPerson) Then
			AddPropsToHtml5(HTMLText, NStr("vi = 'Liên hệ:';
											|ru = 'Контакт:';
											|en = 'Contact:'; fa = 'تماس:';
											|it = 'Contatti:';
											|pl = 'Contact:';
											|tr = 'İletişim:'"), DescriptionOfParty.ContactPerson);
		EndIf;
		
		HTMLText = HTMLText + "<p>";
	EndDo;
	
	HTMLText = HTMLText + "</td><td>";
	
EndProcedure

// Caption to the number of days by declension
//
Function GetSignatureDays(NumberOfDays)
	
	If NumberOfDays > 10 And NumberOfDays < 20 Then
		Signature = NStr("vi = 'ngày';
						|ru = 'дня';
						|en = 'days'; fa = 'روز';
						|it = 'del giorno';
						|pl = 'dnia';
						|tr = 'gün'");
	Else
		LastTwoDigits = NumberOfDays - Int(NumberOfDays / 100) * 100;
		LastDigit = NumberOfDays - Int(NumberOfDays / 10) * 10;
		
		If LastDigit = 0 Then
			Signature = NStr("vi = 'ngày';
							|ru = 'дня';
							|en = 'days'; fa = 'روز';
							|it = 'del giorno';
							|pl = 'dnia';
							|tr = 'gün'");
		ElsIf LastTwoDigits > 10 And LastTwoDigits < 20 Then
			Signature = NStr("vi = 'ngày';
							|ru = 'дня';
							|en = 'days'; fa = 'روز';
							|it = 'del giorno';
							|pl = 'dnia';
							|tr = 'gün'");
		ElsIf LastTwoDigits < 10 Or LastTwoDigits > 20 Then
			If LastDigit = 1 Then
				Signature = NStr("vi = 'ngày';
								|ru = 'день';
								|en = 'day'; fa = 'روز';
								|it = 'giorno';
								|pl = 'dzień';
								|tr = 'gün'");
			ElsIf LastDigit < 5 Then
				Signature = NStr("vi = 'ngày';
								|ru = 'дня';
								|en = 'days'; fa = 'روز';
								|it = 'del giorno';
								|pl = 'dnia';
								|tr = 'gün'");
			Else
				Signature = NStr("vi = 'ngày';
								|ru = 'дня';
								|en = 'days'; fa = 'روز';
								|it = 'del giorno';
								|pl = 'dnia';
								|tr = 'gün'");
			EndIf;
		EndIf;
	EndIf;
	
	Return Signature;
	
EndFunction

// Caption to the number of hours by declension
//
Function GetWatchSignature(NumberOfHours)
	
	If NumberOfHours > 10 And NumberOfHours < 20 Then
		Signature = NStr("vi = 'giờ';
						|ru = 'часов';
						|en = 'hours'; fa = 'ساعت';
						|it = 'ore';
						|pl = 'godzin';
						|tr = 'saat'");
	Else
		DueDate = NumberOfHours - Int(NumberOfHours / 10) * 10;
		If DueDate = 0 Then
			Signature = NStr("vi = 'giờ';
							|ru = 'часов';
							|en = 'hours'; fa = 'ساعت';
							|it = 'ore';
							|pl = 'godzin';
							|tr = 'saat'");
		ElsIf DueDate = 1 Then
			Signature = NStr("vi = 'giờ';
							|ru = 'час';
							|en = 'hour'; fa = 'hour';
							|it = 'ora';
							|pl = 'godzina';
							|tr = 'saat'");
		ElsIf DueDate < 5 Then
			Signature = NStr("vi = 'giờ';
							|ru = 'часов';
							|en = 'hours'; fa = 'ساعت';
							|it = 'ore';
							|pl = 'godzin';
							|tr = 'saat'");
		Else
			Signature = NStr("vi = 'giờ';
							|ru = 'часов';
							|en = 'hours'; fa = 'ساعت';
							|it = 'ore';
							|pl = 'godzin';
							|tr = 'saat'");
		EndIf;
	EndIf;
	
	Return Signature;
	
EndFunction

#EndRegion