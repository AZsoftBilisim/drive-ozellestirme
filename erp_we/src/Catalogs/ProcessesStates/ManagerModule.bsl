#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
//  Items   - ValueTable - filling data. The composition of the columns corresponds to the set of Attributes, contains:
//    * Description - String -
//    * LongDesc     - String -      
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	DefaultLanguageCode = Common.DefaultLanguageCode();

	#Region SalesProcesses
	Item = Items.Add();
	Item.PredefinedDataName = "SalesProcesses";
	Item.Description = NStr("vi = 'Quy trình bán hàng';
							|ru = 'Процессы продаж';
							|en = 'Sales processes'; fa = 'Sales processes';
							|it = 'Processi di vendite';
							|pl = 'Procesy sprzedaży';
							|tr = 'Satış süreçleri'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 0;
	#EndRegion

	#Region LiabilityFulfillment
	Item = Items.Add();
	Item.PredefinedDataName = "LiabilityFulfillment";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Thực hiện nghĩa vụ';
							|ru = 'Выполнение обязательств';
							|en = 'Fulfill contract'; fa = 'Fulfill contract';
							|it = 'Esecuzione degli obblighi';
							|pl = 'Wykonania zobowiązań';
							|tr = 'Yükümlülüklerin yerine getirilmesi'", DefaultLanguageCode);
	Item.LongDesc = NStr("vi = 'Trong giai đoạn này cần thanh toán và giao tất cả hàng hóa theo vụ việc.';
						|ru = 'На данном этапе должны быть оплачены и отгружены все товары по сделке.';
						|en = 'During this stage, all sold goods are paid and shipped.'; fa = 'During this stage, all sold goods are paid and shipped.';
						|it = 'La fase attuale prevede che tutti i prodotti nella transazione debbano essere pagati e spediti.';
						|pl = 'Na danym etapie muszą być opłacone i wysłane wszystkie wiersze pozycji w ramach umowy.';
						|tr = 'Bu aşamada, satış fırsatı kapsamındaki tüm ürünlere ödeme yapılmalı ve sevk edilmelidir.'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 9;
	#EndRegion

	#Region OfferRevision
	Item = Items.Add();
	Item.PredefinedDataName = "OfferRevision";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Hoàn thiện đề xuất';
							|ru = 'Доработка предложения';
							|en = 'Offer revision'; fa = 'Offer revision';
							|it = 'Perfezionamento dell''offerta';
							|pl = 'Udoskonalenie oferty';
							|tr = 'Teklifin tamamlanması'", DefaultLanguageCode);
	Item.LongDesc = NStr("vi = 'Giai đoạn này để hoàn thiện báo giá, nếu việc này là cần thiết.';
						|ru = 'Данный этап посвящен доработке коммерческого предложения, если таковая необходима.';
						|en = 'This step is about a sales quotation revision, if required.'; fa = 'This step is about a sales quotation revision, if required.';
						|it = 'La fase attuale è dedicata alla finalizzazione della proposta commerciale, se necessario.';
						|pl = 'Dany etap jest poświęcony dopracowaniu oferty komercyjnej, jeśli jest to konieczne.';
						|tr = 'Bu aşama, gerekmesi durumunda satış teklifinin sonuçlandırılmasına ayrılmıştır.'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 6;
	#EndRegion

	#Region CustomerQualifications
	Item = Items.Add();
	Item.PredefinedDataName = "CustomerQualifications";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Trình độ chuyên môn của khách hàng';
							|ru = 'Квалификация клиента';
							|en = 'Qualify lead'; fa = 'Qualify lead';
							|it = 'Qualifica del cliente';
							|pl = 'Kwalifikacja klienta';
							|tr = 'Müşterinin niteliği'", DefaultLanguageCode);
	Item.LongDesc = NStr("vi = 'Trong giai đoạn này cần xác định và ghi nhận khách hàng là bạn hàng.';
						|ru = 'На данном этапе клиент должен быть определен и зарегистрирован в качестве партнера.';
						|en = 'On this step, the customer should be defined and registered as a partner.'; fa = 'On this step, the customer should be defined and registered as a partner.';
						|it = 'Alla fase attuale il cliente deve essere definito e registrato in qualità di partner.';
						|pl = 'Na danym etapie klient musi być zarejestrowany jako partner.';
						|tr = 'Bu aşamada müşteri tanımlanmalı ve iş ortağı olarak kaydedilmelidir.'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 3;
	#EndRegion

	#Region NewSalesOpportunity
	Item = Items.Add();
	Item.PredefinedDataName = "NewSalesOpportunity";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Vụ việc mới';
							|ru = 'Новая сделка';
							|en = 'New sales opportunity'; fa = 'New sales opportunity';
							|it = 'Nuovo affare';
							|pl = 'Nowa umowa';
							|tr = 'Yeni satış fırsatı'", DefaultLanguageCode);
	Item.LongDesc = NStr("vi = 'Giai đoạn này phản ánh vụ việc đã được ghi nhận, nhưng chưa thực hiện công việc nào liên quan';
						|ru = 'Данный этап отражает факт того, что сделка была зарегистрирована, но никаких других работ по не не проводилось';
						|en = 'This stage shows that the sales opportunity was registered but no other actions were taken'; fa = 'This stage shows that the sales opportunity was registered but no other actions were taken';
						|it = 'Questa fase riflette il fatto che la transazione è stata registrata, ma nessun altro lavoro è stato eseguito.';
						|pl = 'Dany etap odzwierciedla fakt, że umowa została zarejestrowana ale żadne inne prace w jej ramach nie były wykonywane';
						|tr = 'Bu aşama, satış fırsatının kaydedildiği ancak başka bir çalışma yapılmadığı gerçeğini yansıtmaktadır'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 1;
	#EndRegion

	#Region PrimaryContact
	Item = Items.Add();
	Item.PredefinedDataName = "PrimaryContact";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Liên hệ ban đầu';
							|ru = 'Первичный контакт';
							|en = 'Register opportunity'; fa = 'Register opportunity';
							|it = 'Contatto primario';
							|pl = 'Pierwszy kontakt';
							|tr = 'Birincil iletişim'", DefaultLanguageCode);
	Item.LongDesc = NStr("vi = 'Trong giai đoạn này cần ghi nhận giao tiếp ban đầu với khách hàng.';
						|ru = 'На данном этапе необходимо зарегистрировать первичное взаимодействие с клиентом.';
						|en = 'On this step, it is required to register initial interaction with a customer.'; fa = 'On this step, it is required to register initial interaction with a customer.';
						|it = 'In questa fase è necessario registrare l''interazione primaria con il cliente.';
						|pl = 'Na danym etapie należy zarejestrować początkową współpracę z klientem.';
						|tr = 'Bu aşamada, müşteri ile ilk etkileşimi kaydetmeniz gerekmektedir.'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 2;
	#EndRegion

	#Region PreparationForExecutionOfObligations
	Item = Items.Add();
	Item.PredefinedDataName = "PreparationForExecutionOfObligations";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Chuẩn bị thực hiện nghĩa vụ';
							|ru = 'Подготовка к выполнению обязательств';
							|en = 'Sign contract'; fa = 'Sign contract';
							|it = 'Preparazione all''esecuzione degli obblighi';
							|pl = 'Przygotowanie do wykonania zobowiązań';
							|tr = 'Yükümlülüklerin yerine getirilmesi için hazırlık'", DefaultLanguageCode);
	Item.LongDesc = NStr("vi = 'Giai đoạn này dùng để chuẩn bị thực hiện các nghĩa vụ theo vụ việc.';
						|ru = 'Данный этап посвящен подготовке к выполнению обязательств по сделке.';
						|en = 'This stage is about preparation for fulfilling liabilities under the sales opportunity.'; fa = 'This stage is about preparation for fulfilling liabilities under the sales opportunity.';
						|it = 'La fase attuale è dedicata alla preparazione per l''adempimento degli obblighi previsti dalla transazione.';
						|pl = 'Ten etap jest poświęcony do wykonania zobowiązań z tytułu umowy.';
						|tr = 'Bu aşama, satış fırsatı kapsamındaki yükümlülüklerin yerine getirilmesi için hazırlanmaya ayrılmıştır.'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 8;
	#EndRegion

	#Region Presentation
	Item = Items.Add();
	Item.PredefinedDataName = "Presentation";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Thuyết trình';
							|ru = 'Презентация';
							|en = 'Demonstrate product'; fa = 'Demonstrate product';
							|it = 'Presentazione';
							|pl = 'Demonstrate product';
							|tr = 'Sunu'", DefaultLanguageCode);
	Item.LongDesc= NStr("vi = 'Giai đoạn này để thuyết trình, nếu cần.';
						|ru = 'Данный этап посвящен презентации, если таковая необходима.';
						|en = 'This step is about a presentation if it is required.'; fa = 'This step is about a presentation if it is required.';
						|it = 'La fase attuale è dedicata alla presentazione, se necessaria.';
						|pl = 'Dany etap jest poświęcony prezentacji, jeśli jest ona konieczna.';
						|tr = 'Bu aşama, gerekmesi durumunda sunuya ayrılmıştır.'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 5;
	#EndRegion

	#Region HarmonizationOfTerms
	Item = Items.Add();
	Item.PredefinedDataName = "HarmonizationOfTerms";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Thống nhất các điều khoản';
							|ru = 'Согласование условий';
							|en = 'Negotiate terms of sales'; fa = 'Negotiate terms of sales';
							|it = 'Concordanza delle condizioni';
							|pl = 'Uzgodnienie warunków';
							|tr = 'Şartların mutabakatı'", DefaultLanguageCode);
	Item.LongDesc = NStr("vi = 'Trong giai đoạn này cần xác định thỏa thuận với khách hàng, trong đó ghi nhận các điều kiện bán hàng.';
						|ru = 'На данном этапе должно быть определено соглашение с клиентом, определяющее условия продаж.';
						|en = 'On this step, determine a customer agreement that specifies sales terms and conditions.'; fa = 'On this step, determine a customer agreement that specifies sales terms and conditions.';
						|it = 'La fase attuale, è necessario definire un accordo con il cliente, definendo le condizioni di vendita.';
						|pl = 'Na danym etapie musi być określone porozumienie z klientem, określające warunki sprzedaży.';
						|tr = 'Bu aşamada, satış şart ve hükümlerini tanımlayan satış koşulları  tanımlanmalıdır.'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 7;
	#EndRegion

	#Region ProposalGeneration
	Item = Items.Add();
	Item.PredefinedDataName = "ProposalGeneration";
	Item.Parent = Catalogs.ProcessesStates.SalesProcesses;
	Item.Description = NStr("vi = 'Lập đề xuất';
							|ru = 'Формирование предложения';
							|en = 'Prepare proposal'; fa = 'Prepare proposal';
							|it = 'Formazione dell''offerta';
							|pl = 'Utworzenie oferty';
							|tr = 'Teklifin oluşturulması'", DefaultLanguageCode);
	Item.LongDesc = NStr("vi = 'Giai đoạn này để lập báo giá.';
						|ru = 'Данный этап посвящен формированию коммерческого предложения.';
						|en = 'This step is about a sales quotation creation.'; fa = 'This step is about a sales quotation creation.';
						|it = 'La fase attuale è dedicata alla formazione di offerte commerciali.';
						|pl = 'Dany etap jest poświęcony tworzeniu oferty komercyjnej.';
						|tr = 'Bu aşama, satış teklifinin oluşturulmasına ayrılmıştır.'", DefaultLanguageCode);
	Item.AddlOrderingAttribute = 4;
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.ProcessesStates - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)

	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.ProcessesStates);
	
EndProcedure

#EndRegion
	
#Region Private

#Region InfobaseUpdate

// Fills in details for additional ordering of sales process stages.
// Called when the IB is initially filled in.
//
Procedure InitialFillingOfSequenceOfStagesOfSalesProcesses() Export
	
	Stages = New Map;
	Stages.Insert(Catalogs.ProcessesStates.NewSalesOpportunity,                       1);
	Stages.Insert(Catalogs.ProcessesStates.PrimaryContact,                  2);
	Stages.Insert(Catalogs.ProcessesStates.CustomerQualifications,               3);
	Stages.Insert(Catalogs.ProcessesStates.ProposalGeneration,           4);
	Stages.Insert(Catalogs.ProcessesStates.Presentation,                       5);
	Stages.Insert(Catalogs.ProcessesStates.OfferRevision,              6);
	Stages.Insert(Catalogs.ProcessesStates.HarmonizationOfTerms,               7);
	Stages.Insert(Catalogs.ProcessesStates.PreparationForExecutionOfObligations, 8);
	Stages.Insert(Catalogs.ProcessesStates.LiabilityFulfillment,            9);
	
	For Each Stage In Stages Do
		StageObject = Stage.Key.GetObject();
		StageObject.AddlOrderingAttribute = Stage.Value;
		StageObject.LongDesc                  = DescriptionOfPredefinedStateOfProcess(Stage.Key);
		StageObject.Write();
	EndDo;
	
EndProcedure

Function DescriptionOfPredefinedStateOfProcess(ProcessStep);
	
	If ProcessStep = Catalogs.ProcessesStates.NewSalesOpportunity Then
	
		Return NStr("vi = 'Giai đoạn này phản ánh vụ việc đã được ghi nhận, nhưng chưa tiến hành công việc nào liên quan';
					|ru = 'Данный этап отражает факт того, что сделка была зарегистрирована, но никаких других работ по не не проводилось';
					|en = 'This stage shows that the sales opportunity was registered but no other actions were taken'; fa = 'This stage shows that the sales opportunity was registered but no other actions were taken';
					|it = 'Questa fase riflette il fatto che la transazione è stata registrata, ma nessun altro lavoro è stato eseguito.';
					|pl = 'Dany etap odzwierciedla fakt, że umowa została zarejestrowana ale żadne inne prace w jej ramach nie były wykonywane';
					|tr = 'Bu aşama, satış fırsatının kaydedildiği ancak başka bir çalışma yapılmadığı gerçeğini yansıtmaktadır'");
	
	ElsIf ProcessStep = Catalogs.ProcessesStates.PrimaryContact Then
	
		Return NStr("vi = 'Trong giai đoạn này cần ghi nhận giao tiếp ban đầu với khách hàng.';
					|ru = 'На данном этапе необходимо зарегистрировать первичное взаимодействие с клиентом.';
					|en = 'On this step, it is required to register initial interaction with a customer.'; fa = 'On this step, it is required to register initial interaction with a customer.';
					|it = 'In questa fase è necessario registrare l''interazione primaria con il cliente.';
					|pl = 'Na danym etapie należy zarejestrować początkową współpracę z klientem.';
					|tr = 'Bu aşamada, müşteri ile ilk etkileşimi kaydetmeniz gerekmektedir.'");
		
	ElsIf ProcessStep = Catalogs.ProcessesStates.CustomerQualifications Then
	
		Return NStr("vi = 'Trong giai đoạn này cần xác định và ghi nhận khách hàng là bạn hàng.';
					|ru = 'На данном этапе клиент должен быть определен и зарегистрирован в качестве партнера.';
					|en = 'On this step, the customer should be defined and registered as a partner.'; fa = 'On this step, the customer should be defined and registered as a partner.';
					|it = 'Alla fase attuale il cliente deve essere definito e registrato in qualità di partner.';
					|pl = 'Na danym etapie klient musi być zarejestrowany jako partner.';
					|tr = 'Bu aşamada müşteri tanımlanmalı ve iş ortağı olarak kaydedilmelidir.'");
		
	ElsIf ProcessStep = Catalogs.ProcessesStates.ProposalGeneration Then
	
		Return NStr("vi = 'Giai đoạn này để lập báo giá.';
					|ru = 'Данный этап посвящен формированию коммерческого предложения.';
					|en = 'This step is about a sales quotation creation.'; fa = 'This step is about a sales quotation creation.';
					|it = 'La fase attuale è dedicata alla formazione di offerte commerciali.';
					|pl = 'Dany etap jest poświęcony tworzeniu oferty komercyjnej.';
					|tr = 'Bu aşama, satış teklifinin oluşturulmasına ayrılmıştır.'");
		
	ElsIf ProcessStep = Catalogs.ProcessesStates.Presentation Then
	
		Return NStr("vi = 'Giai đoạn này để thuyết trình, nếu cần.';
					|ru = 'Данный этап посвящен презентации, если таковая необходима.';
					|en = 'This step is about a presentation if it is required.'; fa = 'This step is about a presentation if it is required.';
					|it = 'La fase attuale è dedicata alla presentazione, se necessaria.';
					|pl = 'Dany etap jest poświęcony prezentacji, jeśli jest ona konieczna.';
					|tr = 'Bu aşama, gerekmesi durumunda sunuya ayrılmıştır.'");
		
	ElsIf ProcessStep = Catalogs.ProcessesStates.OfferRevision Then
	
		Return NStr("vi = 'Giai đoạn này để hoàn thiện báo giá, nếu cần.';
					|ru = 'Данный этап посвящен доработке коммерческого предложения, если таковая необходима.';
					|en = 'This step is about a sales quotation revision, if required.'; fa = 'This step is about a sales quotation revision, if required.';
					|it = 'La fase attuale è dedicata alla finalizzazione della proposta commerciale, se necessario.';
					|pl = 'Dany etap jest poświęcony dopracowaniu oferty komercyjnej, jeśli jest to konieczne.';
					|tr = 'Bu aşama, gerekmesi durumunda satış teklifinin sonuçlandırılmasına ayrılmıştır.'");
		
	ElsIf ProcessStep = Catalogs.ProcessesStates.HarmonizationOfTerms Then
	
		Return NStr("vi = 'Trong giai đoạn này cần xác định thỏa thuận với khách hàng, trong đó có điều kiện bán hàng.';
					|ru = 'На данном этапе должно быть определено соглашение с клиентом, определяющее условия продаж.';
					|en = 'On this step, determine an agreement with customer that specifies sales terms and conditions.'; fa = 'On this step, determine an agreement with customer that specifies sales terms and conditions.';
					|it = 'La fase attuale, è necessario definire un accordo con il cliente, definendo le condizioni di vendita.';
					|pl = 'Na danym etapie musi być określone porozumienie z klientem, określające warunki sprzedaży.';
					|tr = 'Bu aşamada, satış şart ve hükümlerini tanımlayan satış koşulları  tanımlanmalıdır.'");
		
	ElsIf ProcessStep = Catalogs.ProcessesStates.PreparationForExecutionOfObligations Then
	
		Return NStr("vi = 'Giai đoạn này để chuẩn bị cho việc thực hiện các nghĩa vụ theo vụ việc.';
					|ru = 'Данный этап посвящен подготовке к выполнению обязательств по сделке.';
					|en = 'This stage is about preparation for fulfilling liabilities under the sales opportunity.'; fa = 'This stage is about preparation for fulfilling liabilities under the sales opportunity.';
					|it = 'La fase attuale è dedicata alla preparazione per l''adempimento degli obblighi previsti dalla transazione.';
					|pl = 'Ten etap jest poświęcony do wykonania zobowiązań z tytułu umowy.';
					|tr = 'Bu aşama, satış fırsatı kapsamındaki yükümlülüklerin yerine getirilmesi için hazırlanmaya ayrılmıştır.'");
		
	ElsIf ProcessStep = Catalogs.ProcessesStates.LiabilityFulfillment Then
	
		Return NStr("vi = 'Trong giai đoạn này cần thanh toán và giao tất cả hàng hóa theo vụ việc.';
					|ru = 'На данном этапе должны быть оплачены и отгружены все товары по сделке.';
					|en = 'During this stage, all sold goods are paid and shipped.'; fa = 'During this stage, all sold goods are paid and shipped.';
					|it = 'La fase attuale prevede che tutti i prodotti nella transazione debbano essere pagati e spediti.';
					|pl = 'Na danym etapie muszą być opłacone i wysłane wszystkie wiersze pozycji w ramach umowy.';
					|tr = 'Bu aşamada, satış fırsatı kapsamındaki tüm ürünlere ödeme yapılmalı ve sevk edilmelidir.'");
	
	Else
	
		Return "";
	
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
