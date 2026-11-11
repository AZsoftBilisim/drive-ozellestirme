#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TypeOfSelectionObject = Parameters.TypeOfSelectionObject;
	
	// We will collect the details available for search, without contacting the service.
	AddSearchDetails("name", "Description", "String");
	If TypeOfSelectionObject = "DMIncomingDocument"
			Or TypeOfSelectionObject = "DMInternalDocument"
			Or TypeOfSelectionObject = "DMOutgoingDocument" Then
		AddSearchDetails("documentType", NStr("vi = 'Dạng văn bản';
												|ru = 'Вид документа';
												|en = 'Document kind'; fa = 'نوع سند';
												|it = 'Tipologia di documento';
												|pl = 'Rodzaj dokumentu';
												|tr = 'Belge türü'"), TypeOfSelectionObject + "Type");
		AddSearchDetails("summary", NStr("vi = 'Nội dung';
										|ru = 'Содержание';
										|en = 'Content'; fa = 'محتوا';
										|it = 'Contenuto';
										|pl = 'Content';
										|tr = 'İçerik'"), "String");
		AddSearchDetails("comment", NStr("vi = 'Ghi chú';
										|ru = 'Комментарий';
										|en = 'Comment'; fa = 'توضیحات';
										|it = 'Commento';
										|pl = 'Comment';
										|tr = 'Yorum'"), "String");
		AddSearchDetails("regNumber", NStr("vi = 'Số đăng ký';
											|ru = 'Рег. номер';
											|en = 'Registration number'; fa = 'شماره ثبت';
											|it = 'Numero di registrazione';
											|pl = 'Numer rejestracyjny';
											|tr = 'Kayıt sayı'"), "String");
		AddSearchDetails("regDate", NStr("vi = 'Ngày đăng ký';
										|ru = 'Дата регистрации';
										|en = 'Registration date'; fa = 'تاریخ ثبت';
										|it = 'Data di registrazione';
										|pl = 'Data rejestracji';
										|tr = 'Kayıt tarihi'"), "Date");
		AddSearchDetails("sum", NStr("vi = 'Số tiền';
									|ru = 'Сумма';
									|en = 'Amount'; fa = 'مبلغ';
									|it = 'Importo';
									|pl = 'Wartość';
									|tr = 'Tutar'"), "Number");
		AddSearchDetails("currency", NStr("vi = 'Tiền tệ';
											|ru = 'Валюта';
											|en = 'Currency'; fa = 'ارز';
											|it = 'Valuta';
											|pl = 'Waluta';
											|tr = 'Para birimi'"), "DMCurrency");
		AddSearchDetails("organization", NStr("vi = 'Doanh nghiệp';
												|ru = 'Организация';
												|en = 'Company'; fa = 'Company';
												|it = 'Azienda';
												|pl = 'Firma';
												|tr = 'İş yeri'"), "DMOrganization");
		AddSearchDetails("subdivision", NStr("vi = 'Bộ phận';
											|ru = 'Подразделение';
											|en = 'Business unit'; fa = 'Business unit';
											|it = 'Reparto';
											|pl = 'Dział';
											|tr = 'Departman'"), "DMSubdivision");
		AddSearchDetails("accessLevel", NStr("vi = 'Độ mật';
											|ru = 'Гриф доступа';
											|en = 'Access label'; fa = 'برچسب دسترسی';
											|it = 'Dicitura di accesso';
											|pl = 'Poziom dostępu';
											|tr = 'Erişim etiketi'"), "DMAccessLevel");
		AddSearchDetails("performanceDate", NStr("vi = 'Thời hạn thực hiện';
												|ru = 'Срок исполнения';
												|en = 'Due date'; fa = 'تاریخ سررسید';
												|it = 'Tempo di esecuzione';
												|pl = 'Data realizacji';
												|tr = 'Son tarih'"), "Date");
		AddSearchDetails("activityMatter", NStr("vi = 'Vấn đề nghiệp vụ';
												|ru = 'Вопрос деятельности';
												|en = 'Activity issue'; fa = 'موضوع فعالیت';
												|it = 'Problema di attività';
												|pl = 'Kwestia działalności';
												|tr = 'Faaliyet sorusu'"), "DMActivityMatter");
		AddSearchDetails("responsible", NStr("vi = 'Người chịu trách nhiệm';
											|ru = 'Ответственный';
											|en = 'Responsible person'; fa = 'شخص مسئول';
											|it = 'Responsabile';
											|pl = 'Responsible person';
											|tr = 'Sorumlu'"), "DMUser");
		AddSearchDetails("project", NStr("vi = 'Dự án';
										|ru = 'Проект';
										|en = 'Project'; fa = 'پروژه';
										|it = 'Progetto';
										|pl = 'Project';
										|tr = 'Proje'"), "DMProject");
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.7.1") Then
			AddSearchDetails("status", NStr("vi = 'Trạng thái';
											|ru = 'Состояние';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Stato';
											|pl = 'State';
											|tr = 'Durum'"), "DMDocumentStatus");
		EndIf;
	EndIf;
	
	If TypeOfSelectionObject = "DMIncomingDocument" Then
		AddSearchDetails("externalNumber", NStr("vi = 'Số chứng từ đầu ra';
												|ru = 'Исходящий номер';
												|en = 'Outgoing number'; fa = 'شماره صادره';
												|it = 'Numero in uscita';
												|pl = 'Numer wychodzący';
												|tr = 'Giden sayı'"), "String");
		AddSearchDetails("externalDate", NStr("vi = 'Ngày chứng từ đầu ra';
												|ru = 'Исходящая дата';
												|en = 'Outgoing date'; fa = 'تاریخ صادره';
												|it = 'Data in uscita';
												|pl = 'Data wychodząca';
												|tr = 'Giden tarih'"), "Date");
		AddSearchDetails("correspondent", NStr("vi = 'Người gửi';
												|ru = 'Отправитель';
												|en = 'Sender'; fa = 'فرستنده';
												|it = 'Mittente';
												|pl = 'Sender';
												|tr = 'Gönderen'"), "DMCorrespondent");
		AddSearchDetails("signer", NStr("vi = 'Người ký';
										|ru = 'Подписал';
										|en = 'Signed by'; fa = 'امضاشده توسط';
										|it = 'Firmato';
										|pl = 'Signed by';
										|tr = 'İmzaladı'"), "DMContactPerson");
		AddSearchDetails("addressee", NStr("vi = 'Người nhận';
											|ru = 'Адресат';
											|en = 'Addressee'; fa = 'مخاطب';
											|it = 'Destinatario';
											|pl = 'Addressee';
											|tr = 'Alıcı'"), "DMUser");
		AddSearchDetails("deliveryMethod", NStr("vi = 'Phương thức nhận';
												|ru = 'Способ получения';
												|en = 'Receipt method'; fa = 'روش دریافت';
												|it = 'Metodo di ricezione';
												|pl = 'Sposób odbioru';
												|tr = 'Alma yöntemi'"), "DMDeliveryMethod");
		
	ElsIf TypeOfSelectionObject = "DMInternalDocument" Then
		AddSearchDetails("folder", NStr("vi = 'Thư mục';
										|ru = 'Папка';
										|en = 'Folder'; fa = 'پوشه';
										|it = 'Cartella';
										|pl = 'Folder';
										|tr = 'Klasör'"), "DMInternalDocumentFolder");
		AddSearchDetails("beginDate", NStr("vi = 'Ngày bắt đầu hiệu lực';
											|ru = 'Дата начала действия';
											|en = 'Effective date'; fa = 'تاریخ اعتبار';
											|it = 'Data di inizio validità';
											|pl = 'Data rozpoczęcia działania';
											|tr = 'Geçerlilik başlangıç tarihi'"), "Date");
		AddSearchDetails("endDate", NStr("vi = 'Ngày kết thúc hiệu lực';
										|ru = 'Дата окончания действия';
										|en = 'Expiration date'; fa = 'تاریخ انقضا';
										|it = 'Data di fine validità';
										|pl = 'Data wygaśnięcia';
										|tr = 'Geçerlilik bitiş tarihi'"), "Date");
		AddSearchDetails("openEnded", NStr("vi = 'Không thời hạn';
											|ru = 'Бессрочный';
											|en = 'Unlimited'; fa = 'نامحدود';
											|it = 'Illimitato';
											|pl = 'Unlimited';
											|tr = 'Süresiz'"), "Boolean");
		If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
			AddSearchDetails("correspondent", NStr("vi = 'Cơ sở thông tin trao đổi';
													|ru = 'Корреспондент';
													|en = 'Correspondent'; fa = 'Correspondent';
													|it = 'Corrispondente';
													|pl = 'Korespondent';
													|tr = 'Muhabir'"), "DMCorrespondent");
		Else
			AddSearchDetails("correspondent", NStr("vi = 'Đối tác';
													|ru = 'Контрагент';
													|en = 'Counterparty'; fa = 'طرف حساب';
													|it = 'Controparte';
													|pl = 'Kontrahent';
													|tr = 'Cari hesap'"), "DMCorrespondent");
		EndIf;
		AddSearchDetails("contactPerson", NStr("vi = 'Người liên hệ';
												|ru = 'Контактное лицо';
												|en = 'Contact person'; fa = 'شخص تماس';
												|it = 'Contatto';
												|pl = 'Osoba do kontaktu';
												|tr = 'İrtibat kişisi'"), "DMContactPerson");
		AddSearchDetails("signer", NStr("vi = 'Người duyệt';
										|ru = 'Утвердил';
										|en = 'Approved'; fa = 'تأییدشده';
										|it = 'Approvato';
										|pl = 'Approved';
										|tr = 'Onaylandı'"), "DMUser");
		AddSearchDetails("author", NStr("vi = 'Người soạn';
										|ru = 'Подготовил';
										|en = 'Prepared'; fa = 'آماده‌شده';
										|it = 'Preparato';
										|pl = 'Prepared';
										|tr = 'Hazırlayan'"), "DMUser");
		AddSearchDetails("prolongationProcedure", NStr("vi = 'Trình tự gia hạn';
														|ru = 'Порядок продления';
														|en = 'Extension procedure'; fa = 'رویه تمدید';
														|it = 'Ordine di proroga';
														|pl = 'Tryb przedłużenia';
														|tr = 'Uzatma prosedürü'"), "DMProlongationProcedure");
		
	ElsIf TypeOfSelectionObject = "DMOutgoingDocument" Then
		AddSearchDetails("signer", NStr("vi = 'Người ký';
										|ru = 'Подписал';
										|en = 'Signed by'; fa = 'امضاشده توسط';
										|it = 'Firmato';
										|pl = 'Signed by';
										|tr = 'İmzaladı'"), "DMUser");
		AddSearchDetails("author", NStr("vi = 'Người soạn';
										|ru = 'Подготовил';
										|en = 'Prepared'; fa = 'آماده‌شده';
										|it = 'Preparato';
										|pl = 'Prepared';
										|tr = 'Hazırlayan'"), "DMUser");
		
	ElsIf TypeOfSelectionObject = "DMCorrespondent" Then
		AddSearchDetails("inn", NStr("vi = 'MST';
									|ru = 'ИНН';
									|en = 'TIN'; fa = 'شناسه مالیاتی';
									|it = 'Codice Fiscale';
									|pl = 'NIP';
									|tr = 'VKN'"), "String");
		AddSearchDetails("kpp", NStr("vi = 'Mã chi nhánh';
									|ru = 'КПП';
									|en = 'KPP'; fa = 'KPP';
									|it = 'Codice Causale Di Registrazione Fiscale';
									|pl = 'KPE (Kod Przyczyny wniesienia do Ewidencji)';
									|tr = 'KPP'"), "String");
		AddSearchDetails("okpo", NStr("vi = 'Mã doanh nghiệp';
										|ru = 'Код по ОКПО';
										|en = 'OKPO code'; fa = 'کد OKPO';
										|it = 'Codice secondo il classificatore russo di imprese e organizzazioni';
										|pl = 'Kod wg OKVED';
										|tr = 'OKPO kodu'"), "String");
		AddSearchDetails("fullName", NStr("vi = 'Tên đầy đủ';
											|ru = 'Полное наименование';
											|en = 'Full description'; fa = 'شرح کامل';
											|it = 'Nome completo';
											|pl = 'Pełna nazwa';
											|tr = 'Tam adı'"), "String");
		AddSearchDetails("comment", NStr("vi = 'Ghi chú';
										|ru = 'Комментарий';
										|en = 'Comment'; fa = 'توضیحات';
										|it = 'Commento';
										|pl = 'Comment';
										|tr = 'Yorum'"), "String");
		AddSearchDetails("privatePerson", NStr("vi = 'Cá nhân';
												|ru = 'Физическое лицо';
												|en = 'Person'; fa = 'شخص';
												|it = 'Persona fisica';
												|pl = 'Osoba fizyczna';
												|tr = 'Gerçek kişi'"), "DMPrivatePerson");
		AddSearchDetails("legalPrivatePerson", NStr("vi = 'Pháp nhân/cá nhân';
													|ru = 'Юр./физ. лицо';
													|en = 'Legal entity/person'; fa = 'Legal entity/person';
													|it = 'Persona giuridica / persona fisica';
													|pl = 'Os. praw./fiz.';
													|tr = 'Tüzel./Gerçek. kişi'"), "DMLegalPrivatePerson");
		AddSearchDetails("responsible", NStr("vi = 'Người chịu trách nhiệm';
											|ru = 'Ответственный';
											|en = 'Responsible person'; fa = 'شخص مسئول';
											|it = 'Responsabile';
											|pl = 'Responsible person';
											|tr = 'Sorumlu'"), "DMUser");
		
	EndIf;
	
	SearchAttributes.Sort("Presentation");
	
	SearchImmediately = False;
	
	// There may be preset conditions in the parameters.
	If Parameters.Property("Filter") And Parameters.Filter <> Undefined Then
		For Each PresetCondition In Parameters.Filter Do
			AttributeName = PresetCondition.Key;
			ConditionDetails = PresetCondition.Value;
			FilterStructure1 = New Structure("Name", AttributeName);
			ConditionStrings = SearchAttributes.FindRows(FilterStructure1);
			If ConditionStrings.Count() > 0 Then
				ConditionString = ConditionStrings[0];
				ConditionString.ComparisonOperator = "=";
				If TypeOf(ConditionDetails) = Type("Structure") Then // A difficult condition.
					FillPropertyValues(ConditionString, ConditionDetails);
				Else // The selection value is indicated directly.
					ConditionString.Value = ConditionDetails;
				EndIf;
				AssembleConditionPresentation(ConditionString);
			EndIf;
		EndDo;
		SearchImmediately = True;
	EndIf;
	
	If Parameters.Property("SearchImmediately") Then
		SearchImmediately = Parameters.SearchImmediately;
	EndIf;
	
	If SearchImmediately Then
		DataProcessors.IntegrationWith1CDocumentManagement.PerformSearchByBankingDetails(
			TypeOfSelectionObject,
			FilterStructure1(),
			AddressInTempStorage,
			NumberOfResults,
			LimitNumberOfResults);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not SearchImmediately Or NumberOfResults = 0 Then
		Return;
	EndIf;
	
	AttachIdleHandler("ProcessSearchResults", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationSimpleSearchClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	FormParameters.Insert("Filter", FilterStructure1());
	FormParameters.Insert("SearchImmediately", False);
	Close();
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingObjectBySearch",
		FormParameters,
		ThisObject,
		New UUID,,,
		CallbackDescriptionOnClose,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSearchAttributes

&AtClient
Procedure SearchAttributesOnActivateRow(Item)
	
	Type = Items.SearchAttributes.CurrentData.ValueType;
	Items.SearchAttributesConditionPresentation.TextEdit =
		Type = "String" Or Type = "Number" Or Type = "Date";
	
EndProcedure

&AtClient
Procedure SearchAttributesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData =  Items.SearchAttributes.CurrentData;
	ConditionPresentationElement = Items.SearchAttributesConditionPresentation;
	
	If CurrentData.ValueType = "String" Then
		ConditionPresentationElement.TypeRestriction = New TypeDescription("String");
		ConditionPresentation = CurrentData.Value;
		If Left(ConditionPresentation, 1) = "%" Then
			ConditionPresentation = Mid(ConditionPresentation, 2);
		EndIf;
		If Right(ConditionPresentation, 1) = "%" Then
			ConditionPresentation = Left(ConditionPresentation, StrLen(ConditionPresentation) - 1);
		EndIf;
		CurrentData.ConditionPresentation = ConditionPresentation;
		
	ElsIf CurrentData.ValueType = "Number" Then
		ConditionPresentationElement.TypeRestriction = New TypeDescription(CurrentData.ValueType);
		CurrentData.ConditionPresentation = CurrentData.Value;
		
	ElsIf CurrentData.ValueType = "Date" Then
		ConditionPresentationElement.TypeRestriction = New TypeDescription(
			"Date",,, New DateQualifiers(DateFractions.Date));
		CurrentData.ConditionPresentation = CurrentData.Value;
		
	ElsIf CurrentData.ValueType = "Boolean" Then
		ConditionPresentationElement.TypeRestriction = New TypeDescription("Boolean");
		
	Else // Reference type.
		ConditionPresentationElement.TypeRestriction = New TypeDescription("String");
		
	EndIf;
	
EndProcedure
	
&AtClient
Procedure SearchAttributesOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	CurrentData =  Item.CurrentData;
	
	EnteredValue = CurrentData.ConditionPresentation;
	If Not ValueIsFilled(EnteredValue) Then // We consider manual cleaning to be a rejection of the search.
		CurrentData.ComparisonOperator = "";
		
	ElsIf Not ValueIsFilled(CurrentData.ComparisonOperator) Then // Assign a condition.
		If CurrentData.ValueType = "String" Then
			CurrentData.ComparisonOperator = "LIKE";
			CurrentData.Value = "%" + EnteredValue + "%";
		ElsIf CurrentData.ValueType = "Date" Then
			CurrentData.ComparisonOperator = ">=";
			CurrentData.Value = EnteredValue;
		ElsIf CurrentData.ValueType = "Number" Then
			CurrentData.ComparisonOperator = "=";
			CurrentData.Value = EnteredValue;
		EndIf;
		
	Else // The condition already exists, only the value changes.
		If CurrentData.ValueType = "String" And CurrentData.ComparisonOperator = "LIKE" Then
			// Let's keep the nuances of searching by similarity.
			CurrentData.Value = ?(Left(CurrentData.Value, 1) = "%", "%", "")
				+ EnteredValue + ?(Right(CurrentData.Value, 1) = "%", "%", "");
		Else
			CurrentData.Value = EnteredValue;
		EndIf;
		
	EndIf;
	
	AssembleConditionPresentation(CurrentData);
	
EndProcedure

&AtClient
Procedure SearchAttributesConditionPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Item.Parent.CurrentData;
	If CurrentData.ValueType = "Boolean" Then // The standard drop-down list is fine.
		Return;
	EndIf;
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("SearchDetailsPresentationOfConditionCompletionOfSelection",
		ThisObject, Item.Parent);
	
	If CurrentData.ValueType = "String"
		Or CurrentData.ValueType = "Date"
		Or CurrentData.ValueType = "Number" Then
		NameOfInputForm = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.EnteringSearchDetails"
			+ CurrentData.ValueType;
		FormParameters = New Structure;
		FormParameters.Insert("Title", CurrentData.Presentation);
		FormParameters.Insert("Value", CurrentData.Value);
		FormParameters.Insert("ComparisonOperator", CurrentData.ComparisonOperator);
		FormParameters.Insert("Value2", CurrentData.Value2);
		FormParameters.Insert("ComparisonOperator2", CurrentData.ComparisonOperator2);
		OpenForm(NameOfInputForm, FormParameters, ThisObject,,,,
			CallbackDescription, FormWindowOpeningMode.LockWholeInterface);
		
	Else // The reference type is UP to.
		FormParameters = New Structure;
		FormParameters.Insert("TypeOfSelectionObject", CurrentData.ValueType);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList", FormParameters,
			ThisObject,,,,CallbackDescription, FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchAttributesConditionPresentationClearing(Item, StandardProcessing)
	
	CurrentData =  Items.SearchAttributes.CurrentData;
	
	CurrentData.ComparisonOperator = "";
	CurrentData.Value = "";
	CurrentData.ConditionPresentation = "";
	
EndProcedure

&AtClient
Procedure SearchAttributesConditionPresentationOnChange(Item)
	
	CurrentData = Items.SearchAttributes.CurrentData;
	If CurrentData.ValueType = "Boolean" Then
		CurrentData.ComparisonOperator = "=";
		CurrentData.Value = CurrentData.ConditionPresentation;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToSearch(Command)
	
	ExecuteSearch();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessSearchResults()
	
	If NumberOfResults = 0 Then
		ShowMessageBox(, NStr("vi = 'Điều kiện tìm kiếm đã đặt không cho kết quả nào.';
								|ru = 'Заданные условия поиска не дали ни одного результата.';
								|en = 'No files found with the specified search criteria.'; fa = 'No files found with the specified search criteria.';
								|it = 'Le condizioni di ricerca fornite non hanno portato alcun risultato.';
								|pl = 'Zadane warunki wyszukiwania nie dały żadnych wyników.';
								|tr = 'Belirtilen arama şartları herhangi bir sonuç getirmedi.'"));
		
	ElsIf LimitNumberOfResults <> 0 Then
		Buttons = New ValueList;
		Buttons.Add(True, StrTemplate(
			NStr("vi = 'Có, hiển thị %1 đầu tiên';
				|ru = 'Да, показать первые %1';
				|en = 'Yes, show first %1'; fa = 'Yes, show first %1';
				|it = 'Si, mostrare i primi %1';
				|pl = 'Tak, pokaż pierwsze %1';
				|tr = 'Evet, önce göster %1'"),
				Format(LimitNumberOfResults, "NG=0")));
		Buttons.Add(False, NStr("vi = 'Không, cần làm rõ điều kiện';
								|ru = 'Нет, уточнить условия';
								|en = 'No, clarify the conditions'; fa = 'No, clarify the conditions';
								|it = 'No, indicare condizioni';
								|pl = 'Nie, uściślij warunki';
								|tr = 'Hayır, şartları kesinleştir'"));
		CallbackDescription = New CallbackDescription("ExecuteSearchCompletion", ThisObject);
		ShowQueryBox(CallbackDescription,
			NStr("vi = 'Điều kiện tìm kiếm đã đặt cho rất nhiều kết quả. Hiển thị kết quả?';
				|ru = 'Заданные условия поиска дали слишком много результатов. Показать результаты?';
				|en = 'Too many search results. Show results?'; fa = 'Too many search results. Show results?';
				|it = 'Le condizioni di ricerca fornite hanno trovato troppi risultati. Mostrare i risultati?';
				|pl = 'Zadane warunki wyszukiwania zwróciły zbyt dużo wyników. Pokazać wyniki?';
				|tr = 'Belirtilen arama şartları çok fazla sonuç getirdi. Sonuçları göster?'"),
			Buttons);
		
	Else
		GoToSearchResults();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddSearchDetails(Name, Presentation, Type)
	
	PropsString = SearchAttributes.Add();
	PropsString.Name = Name;
	PropsString.Presentation = Presentation;
	PropsString.ValueType = Type;
	
EndProcedure

// Collects a representation of a search condition from a value and a comparison operator
//
&AtClientAtServerNoContext
Procedure AssembleConditionPresentation(CurrentData)
	
	Type = CurrentData.ValueType;
	Operator = CurrentData.ComparisonOperator;
	Operator2 = CurrentData.ComparisonOperator2;
	Value = CurrentData.Value;
	Value2 = CurrentData.Value2;
	If ValueIsFilled(Operator) Then
		If Type = "String" Then
			If Operator = "=" Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'bằng ""%1""';
						|ru = 'равно ""%1""';
						|en = 'is ""%1""'; fa = 'is ""%1""';
						|it = 'uguale ""%1""';
						|pl = 'równa się ""%1""';
						|tr = 'eşittir ""%1""'"), Value);
			ElsIf Operator = "LIKE" Then
				If Left(Value, 1) = "%"	And Right(Value, 1) = "%" Then
					Presentation = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'có chứa ""%1""';
							|ru = 'содержит ""%1""';
							|en = 'contains ""%1""'; fa = 'contains ""%1""';
							|it = 'contiene ""%1""';
							|pl = 'zawiera ""%1""';
							|tr = '""%1"" içeriyor'"), Mid(Value, 2, StrLen(Value) - 2));
				ElsIf Left(Value, 1) = "%" Then
					Presentation = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'kết thúc vào ""%1""';
							|ru = 'заканчивается на ""%1""';
							|en = 'ends with ""%1""'; fa = 'ends with ""%1""';
							|it = 'finisce il ""%1""';
							|pl = 'kończy się na ""%1""';
							|tr = '""%1"" ile bitiyor'"), Mid(Value,2));
				ElsIf Right(Value, 1) = "%" Then
					Presentation = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'bắt đầu từ ""%1""';
							|ru = 'начинается с ""%1""';
							|en = 'starts with ""%1""'; fa = 'starts with ""%1""';
							|it = 'inizia il ""%1""';
							|pl = 'zaczyna się od ""%1""';
							|tr = '""%1"" ile başlıyor'"), Left(Value, StrLen(Value) - 1));
				EndIf;
			EndIf;
		ElsIf Type = "Number" Then
			If Operator = "=" Then
				Presentation = Value;
			ElsIf ValueIsFilled(Operator2) Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'giữa %1 và %2';
						|ru = 'между %1 и %2';
						|en = 'between %1 and %2'; fa = 'between %1 and %2';
						|it = 'tra %1 e %2';
						|pl = 'między %1 i %2';
						|tr = '%1 ile %2 arasında'"), Value, Value2);
			ElsIf Operator = "<=" Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'đến %1';
						|ru = 'по %1';
						|en = 'to %1'; fa = 'to %1';
						|it = 'fino a %1';
						|pl = 'do %1';
						|tr = '%1 göre'"), Value);
			ElsIf Operator = ">=" Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'ngày %1';
						|ru = 'от %1';
						|en = ', %1'; fa = ', %1';
						|it = 'dal %1';
						|pl = 'od %1';
						|tr = '%1 itibaren'"), Value);
			EndIf;
		ElsIf Type = "Date" Then
			If Operator = "=" Then
				If ValueIsFilled(Value) Then
					Presentation = Format(Value, "DLF=D");
				Else
					Presentation = "(" + NStr("vi = 'trống';
												|ru = 'пустая';
												|en = 'empty'; fa = 'empty';
												|it = 'vuota';
												|pl = 'pusty';
												|tr = 'boş'") + ")";
				EndIf;
			ElsIf ValueIsFilled(Operator2) Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'giữa %1 và %2';
						|ru = 'между %1 и %2';
						|en = 'between %1 and %2'; fa = 'between %1 and %2';
						|it = 'tra %1 e %2';
						|pl = 'między %1 i %2';
						|tr = '%1 ile %2 arasında'"), Format(Value, "DLF=D"), Format(Value2, "DLF=D"));
			ElsIf Operator = "<=" Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'đến %1';
						|ru = 'по %1';
						|en = 'to %1'; fa = 'to %1';
						|it = 'fino a %1';
						|pl = 'do %1';
						|tr = '%1 göre'"), Format(Value, "DLF=D"));
			ElsIf Operator = ">=" Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'từ %1';
						|ru = 'с %1';
						|en = 'from %1'; fa = 'from %1';
						|it = 'da %1';
						|pl = 'od %1';
						|tr = 'itibaren %1'"), Format(Value, "DLF=D"));
			EndIf;
		Else // It is a reference type or Boolean.
			Presentation = String(Value);
		EndIf;
		
	Else // The operator is not specified.
		Presentation = "";
		
	EndIf;
	
	CurrentData.ConditionPresentation = Presentation;
	
EndProcedure

&AtClient
Procedure SearchDetailsPresentationOfConditionCompletionOfSelection(Result, Item) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	If Result.Property("AttributeID") Then // Reference type.
		If Result.AttributeType = "DMFileFolder"
			Or Result.AttributeType = "DMInternalDocumentFolder" Then
			CurrentData.ComparisonOperator = "IN HIERARCHY";
		Else
			CurrentData.ComparisonOperator = "=";
		EndIf;
		CurrentData.Value = Result.AttributePresentation;
		CurrentData.ValueID = Result.AttributeID;
		
	Else // Primitive type.
		CurrentData.Value = Result.Value;
		If Result.Property("ComparisonOperator") Then
			CurrentData.ComparisonOperator = Result.ComparisonOperator;
		EndIf;
		If Result.Property("ComparisonOperator2") Then
			CurrentData.ComparisonOperator2 = Result.ComparisonOperator2;
		EndIf;
		If Result.Property("Value2") Then
			CurrentData.Value2 = Result.Value2;
		EndIf;
		
	EndIf;
	
	AssembleConditionPresentation(CurrentData);
	Item.EndEditRow(True);
	If Result.Property("FindImmediately") And Result.FindImmediately Then
		ExecuteSearch();
	EndIf;
	
EndProcedure

// Packages the selection parameters into a structure intended for transmission to the forms to be opened
//
&AtServer
Function FilterStructure1()
	
	Filter = New Structure;
	For Each SearchDetails In SearchAttributes Do
		If ValueIsFilled(SearchDetails.ComparisonOperator) Then
			Value = New Structure;
			Value.Insert("Presentation", SearchDetails.Presentation);
			Value.Insert("Value", SearchDetails.Value);
			Value.Insert("ValueType", SearchDetails.ValueType);
			Value.Insert("ValueID", SearchDetails.ValueID);
			Value.Insert("ComparisonOperator", SearchDetails.ComparisonOperator);
			If ValueIsFilled(SearchDetails.ComparisonOperator2) Then
				Value.Insert("ComparisonOperator2", SearchDetails.ComparisonOperator2);
				Value.Insert("Value2", SearchDetails.Value2);
			EndIf;
			Value.Insert("ConditionPresentation", SearchDetails.ConditionPresentation);
			Filter.Insert(SearchDetails.Name, Value);
		EndIf;
	EndDo;
	
	Return Filter;
	
EndFunction

&AtClient
Procedure ExecuteSearch()
	
	PerformServerSearch(TypeOfSelectionObject, AddressInTempStorage,
		NumberOfResults, LimitNumberOfResults);
	ProcessSearchResults();
	
EndProcedure

&AtClient
Procedure ExecuteSearchCompletion(Result, Var_Parameters) Export
	
	If Result Then
		GoToSearchResults();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToSearchResults()
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	FormParameters.Insert("Filter", FilterStructure1());
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	Close();
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingObjectBySearchResults",
		FormParameters,
		ThisObject,
		New UUID,,,
		CallbackDescriptionOnClose,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtServer
Procedure PerformServerSearch(TypeOfSelectionObject, AddressInTempStorage, NumberOfResults, LimitNumberOfResults)
	
	DataProcessors.IntegrationWith1CDocumentManagement.PerformSearchByBankingDetails(TypeOfSelectionObject, FilterStructure1(),
		AddressInTempStorage, NumberOfResults, LimitNumberOfResults);
	
EndProcedure

#EndRegion