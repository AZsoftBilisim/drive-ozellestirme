#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisForm, Parameters.Filter);
	 	
	If Parameters.Property("Before") Then
		Before = Parameters.Before;
	EndIf;
	If Parameters.Property("dated") Then
		dated = Parameters.dated;
	EndIf;
	If Parameters.Property("Revenue") Then
		Revenue = Parameters.Revenue;
	EndIf;
	If Parameters.Property("Potential") Then
		Potential = Parameters.Potential;
	EndIf;
	If Parameters.Property("Purchases") Then
		Purchases = Parameters.Purchases;
	EndIf;
	If Parameters.Property("PurchasesFrom") Then
		PurchasesFrom = Parameters.PurchasesFrom;
	EndIf;
	If Parameters.Property("PurchasesBefore") Then
		PurchasesBefore = Parameters.PurchasesBefore;
	EndIf;

	Interests = Parameters.Interests;
	DecryptionList = Parameters.DecryptionList;
	Segment = Parameters.Segment;
	
	If Segment = "AN" Then 
		Title = NStr("vi = 'Khách hàng mới đang hoạt động';
					|ru = 'Активные новые клиенты';
					|en = 'Active new customers'; fa = 'Active new customers';
					|it = 'Attivi nuovi clienti';
					|pl = 'Aktywni nowi klienci';
					|tr = 'Aktif yeni müşteriler'");
	ElsIf Segment = "AP" Then 
		Title = NStr("vi = 'Khách hàng tiềm năng đang hoạt động';
					|ru = 'Активные перспективные клиенты';
					|en = 'Active prospective customers'; fa = 'Active prospective customers';
					|it = 'Clienti attivi potenziali';
					|pl = 'Aktywni perspektywiczni klienci';
					|tr = 'Aktif uzun vadeli müşteriler'");	
	ElsIf Segment = "AV" Then 
		Title = NStr("vi = 'Khách hàng trung thành đang hoạt động';
					|ru = 'Активные верные клиенты';
					|en = 'Active loyal customers'; fa = 'Active loyal customers';
					|it = 'Clienti attivi reali';
					|pl = 'Aktywni wierni klienci';
					|tr = 'Aktif bağlı müşteriler'");	
	ElsIf Segment = "ZN" Then 
		Title = NStr("vi = 'Khách hàng mới không hoạt động';
					|ru = 'Засыпающие новые клиенты';
					|en = 'Sleepy new customers'; fa = 'Sleepy new customers';
					|it = 'Clienti nuovi inattivi';
					|pl = 'Zasypiające nowi klienci';
					|tr = 'Uykuya dalan yeni müşteriler'");	
	ElsIf Segment = "WP" Then 
		Title = NStr("vi = 'Khách hàng tiềm năng không hoạt động';
					|ru = 'Засыпающие перспективные клиенты';
					|en = 'Sleepy prospective customers'; fa = 'Sleepy prospective customers';
					|it = 'Clienti potenziali inattivi';
					|pl = 'Zasypiające perspektywiczni klienci';
					|tr = 'Uykuya dalan uzun vadeli müşteriler'");	
	ElsIf Segment = "ZV_" Then 
		Title = NStr("vi = 'Khách hàng trung thành không hoạt động';
					|ru = 'Засыпающие верные клиенты';
					|en = 'Sleepy loyal customers'; fa = 'Sleepy loyal customers';
					|it = 'Clienti reali inattivi';
					|pl = 'Zasypiające wierni klienci';
					|tr = 'Uykuya dalan bağlı müşteriler'");	
	ElsIf Segment = "SN" Then 
		Title = NStr("vi = 'Khách hàng mới không hoạt động';
					|ru = 'Спящие новые клиенты';
					|en = 'Sleeping new customers'; fa = 'Sleeping new customers';
					|it = 'Clienti nuovi dormienti';
					|pl = 'Śpiące nowi klienci';
					|tr = 'Uyuyan yeni müşteriler'");	
	ElsIf Segment = "SP" Then 
		Title = NStr("vi = 'Khách hàng tiềm năng không hoạt động';
					|ru = 'Спящие перспективные клиенты';
					|en = 'Sleeping prospective customers'; fa = 'Sleeping prospective customers';
					|it = 'Clienti potenziali dormienti';
					|pl = 'Śpiące perspektywiczni klienci';
					|tr = 'Uyuyan uzun vadeli müşteriler'");
	ElsIf Segment = "SV" Then 
		Title = NStr("vi = 'Khách hàng trung thành không hoạt động';
					|ru = 'Спящие верные клиенты';
					|en = 'Sleeping loyal customers'; fa = 'Sleeping loyal customers';
					|it = 'Clienti reali dormienti';
					|pl = 'Śpiące wierni klienci';
					|tr = 'Uyuyan bağlı müşteriler'");	
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	ExecutionResult = Segments();
	If Not ExecutionResult.Status = "Completed2" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("GenerateAlertReport", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(ExecutionResult, CallbackOnCompletion, IdleParameters);
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGeneration");

	EndIf;
		
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If ValueIsFilled(JobID) Then
		CancelBackgroundTask(JobID);
		JobID = Undefined;
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Function Segments()
	
	If ValueIsFilled(JobID) Then
		CancelBackgroundTask(JobID);
		JobID = Undefined;
	EndIf;

SelectionParameterNames = "StartDate, EndDate, PeriodOfUse,DecryptionList,
		|Organization,OrganizationUsage,
		|Manager,ManagerUsage,
		|Products,NomenclatureUsage,
		|CustomerSegment,CustomerSegmentUsage,
		|ProductSegment,ItemSegmentUsage,
		|AmountOfPurchases,PurchaseAmountUsage";

	QueryOptions = New Structure(SelectionParameterNames);
	FillPropertyValues(QueryOptions, ThisForm);
	QueryOptions.Insert("BeginningDateOfPeriod",StartDate);
	QueryOptions.Insert("EndingDateOfPeriod",EndDate);

	BackgroundExecutionParameters=TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"Reports.RepeatedSales.FillInListOfClients", 
		QueryOptions,
		BackgroundExecutionParameters);
	
	JobID = ExecutionResult.JobID;
	StorageAddress       = ExecutionResult.ResultAddress;
	
	If ExecutionResult.Status = "Completed2" Then
		OutputList();
	EndIf;

	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure GenerateAlertReport(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		OutputList();
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelBackgroundTask(JobID)
	TimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

&AtServer
Procedure OutputList()
	
	ResultList = GetFromTempStorage(StorageAddress);
	DeleteFromTempStorage(StorageAddress);
	JobID = Undefined;

	Template = Reports.RepeatedSales.GetTemplate("SegmentCustomers");
		
	SectionHeader = Template.GetArea("Header");
	AreaDescription_ = Template.GetArea("LongDesc");
	
	//Describing the Header area	
	Text = NStr("vi = 'Tổng số: [Count] ([Interests]% khách hàng trong tất cả phân khúc)';
				|ru = 'Всего: [Count] ([Interests]% клиентов из всех сегментов)';
				|en = 'Total: [Count] ([Interests]% customers from all segments)'; fa = 'Total: [Count] ([Interests]% customers from all segments)';
				|it = 'Totale: [Count] ([Interests]% dei clienti da tutti i segmenti)';
				|pl = 'Łącznie: [Count] ([Interests]% klientów ze wszystkich segmentów)';
				|tr = 'Toplam: [Count] ([Interests]% tüm segmentlerden müşteri)'");
	Values = New Structure("Count, Interests", DecryptionList.Count(), Format(Interests,"NFD=0"));		
	SectionHeader.Parameters.CustomerColvo = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
	
	Currency = Constants.ManagementAccountingCurrency.Get();
	Values.Insert("Currency", Currency);

	If Segment = "AN" Or Segment = "AP"
		Or Segment = "AV" Then
		Text = NStr("vi = 'Doanh thu trong kỳ: [Revenue] [Currency]';
					|ru = 'Выручка за период: [Revenue] [Currency]';
					|en = 'Revenue in period: [Revenue] [Currency]'; fa = 'Revenue in period: [Revenue] [Currency]';
					|it = 'Profitto per il periodo: [Revenue] [Currency]';
					|pl = 'Utarg za okres: [Revenue] [Currency]';
					|tr = 'Dönem geliri: [Revenue] [Currency]'");
	    Picture = PictureLib.ReportRepeatedSalesRevenue;
		Values.Insert("Revenue", Format(Revenue,"NFD=0"));
	Else
		Text = NStr("vi = 'Tiềm năng trong kỳ: [Potential]';
					|ru = 'Потенциал за период: [Potential]';
					|en = 'Potential in period: [Potential]'; fa = 'Potential in period: [Potential]';
					|it = 'Potenziale per il periodo: [Potential]';
					|pl = 'Potencjał za okres: [Potential]';
					|tr = 'Dönem potansiyeli: [Potential]'");
	    Picture = PictureLib.ReportRepeatedSalesPotential;
		Values.Insert("Potential", Format(Potential));
	EndIf;
	
	SectionHeader.Parameters.RevenuePotential = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
	
	//Describing the area Description
	If Segment = "AN" Then   
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng mới đang hoạt động';
													|ru = 'Активные новые клиенты';
													|en = 'Active new customers'; fa = 'Active new customers';
													|it = 'Clienti nuovi attivi';
													|pl = 'Aktywni nowi klienci';
													|tr = 'Aktif yeni müşteriler'");  
		Color = New Color(230, 255, 205);
		Values.Insert("Before", Before);
		Text = NStr("vi = 'Các khách hàng đã mua hàng duy nhất vào cuối kỳ, đồng thời giao dịch mua này diễn ra trước khi kết thúc kỳ [Before] ngày.';
					|ru = 'Клиенты, совершившие на конец периода единственную покупку, причем эта покупка состоялась менее [Before] дн. назад, считая с конца периода.';
					|en = 'Customers who made a single purchase as of the period end, where this purchase took place less than [Before] days ago, counting from the period end.'; fa = 'Customers who made a single purchase as of the period end, where this purchase took place less than [Before] days ago, counting from the period end.';
					|it = 'Clienti che alla fine del periodo hanno realizzato un solo acquisto, effettuato meno [Before] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu wykonali jedyny zakup, przy tym ten zakup odbył się mniej niż [Before] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda tek bir satın alma işlemi gerçekleştiren ve bu satın alma işleminin, dönem sonundan itibaren [Before] günden daha az bir süre önce gerçekleştiği müşteriler.'");
	ElsIf Segment = "AP" Then  
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng tiềm năng đang hoạt động';
													|ru = 'Активные перспективные клиенты';
													|en = 'Active prospective customers'; fa = 'Active prospective customers';
													|it = 'Clienti attivi potenziali';
													|pl = 'Aktywni perspektywiczni klienci';
													|tr = 'Aktif uzun vadeli müşteriler'");
		Color = New Color(201, 255, 148);
		Values.Insert("Before", Before);
		Values.Insert("PurchasesFrom", PurchasesFrom);
		Values.Insert("PurchasesBefore", PurchasesBefore);
		Text = NStr("vi = 'Các khách hàng đã mua hàng từ [PurchasesFrom] đến [PurchasesBefore] vào cuối kỳ, đồng thời giao dịch mua này diễn ra trước khi kết thúc kỳ [Before] ngày.';
					|ru = 'Клиенты, совершившие на конец периода от [PurchasesFrom] до [PurchasesBefore] покупок, причем последняя покупка состоялась менее [Before] дн. назад, считая с конца периода.';
					|en = 'Customers who made from [PurchasesFrom] to [PurchasesBefore] purchases as of the period end, where the last purchase took place less than [Before] days ago, counting from the period end.'; fa = 'Customers who made from [PurchasesFrom] to [PurchasesBefore] purchases as of the period end, where the last purchase took place less than [Before] days ago, counting from the period end.';
					|it = 'Clienti che alla fine del periodo hanno realizzato da [PurchasesFrom] a [PurchasesBefore] acquisti, di cui l''ultimo è stato effettuato meno [Before] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu od [PurchasesFrom] do [PurchasesBefore] wykonali zakupów, przy tym ostatni zakup odbył się mniej niż [Before] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda [PurchasesFrom] ile [PurchasesBefore] arası satın alma işlemi gerçekleştiren ve son satın alma işleminin, dönem sonundan itibaren [Before] günden daha az bir süre önce gerçekleştiği müşteriler.'");	
	ElsIf Segment = "AV" Then 
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng trung thành đang hoạt động';
													|ru = 'Активные верные клиенты';
													|en = 'Active loyal customers'; fa = 'Active loyal customers';
													|it = 'Clienti attivi reali';
													|pl = 'Aktywni wierni klienci';
													|tr = 'Aktif bağlı müşteriler'");
		Color = New Color(173, 255, 90);
		Values.Insert("Before", Before);
		Values.Insert("Purchases", Purchases);
		Text = NStr("vi = 'Khách hàng đã mua hàng vào cuối kỳ hơn [Purchases] mua, đồng thời lần mua hàng gần nhất diễn ra trước khi kết thúc kỳ [Before] ngày.';
					|ru = 'Клиенты, совершившие на конец периода более [Purchases] покупок, причем последняя покупка состоялась менее [Before] дн. назад, считая с конца периода.';
					|en = 'Customers who made not more that [Purchases] purchases as of the period end, where the last purchase took place less than [Before] days ago, counting from the period end.'; fa = 'Customers who made not more that [Purchases] purchases as of the period end, where the last purchase took place less than [Before] days ago, counting from the period end.';
					|it = 'Clienti che hanno realizzato più di [Purchases] acquisti alla fine del periodo, di cui l''ultimo acquisto è stato effettuato meno di [Before] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu wykonali ponad [Purchases] zakupów, przy tym ostatni zakup odbył się mniej niż [Before] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda [Purchases] üstü satın alma işlemi gerçekleştiren ve son satın alma işleminin, dönem sonundan itibaren [Before] günden daha az bir süre önce gerçekleştiği müşteriler.'");	
		
	ElsIf Segment = "ZN" Then   
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng mới không hoạt động';
													|ru = 'Засыпающие новые клиенты';
													|en = 'Sleepy new customers'; fa = 'Sleepy new customers';
													|it = 'Clienti nuovi inattivi';
													|pl = 'Zasypiające nowi klienci';
													|tr = 'Uykuya dalan yeni müşteriler'");
		Color = New Color(255, 255, 205);
		Text = NStr("vi = 'Khách hàng đã thực hiện mua hàng duy nhất vào cuối kỳ đồng thời lần mua hàng này diễn ra từ [dated] đến [Before] ngày trước khi kết thúc kỳ.';
					|ru = 'Клиенты, совершившие на конец периода единственную покупку, причём эта покупка состоялась от [dated] до [Before] дн. назад, считая с конца периода.';
					|en = 'Customers who made a single purchase as of the period end, where this purchase took place from [dated] to [Before] days ago, counting from the period end.'; fa = 'Customers who made a single purchase as of the period end, where this purchase took place from [dated] to [Before] days ago, counting from the period end.';
					|it = 'Clienti che alla fine del periodo hanno realizzato un solo acquisto, effettuato da [dated] a [Before] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu wykonali jedyny zakup, przy tym ten zakup odbył się od [dated] do [Before] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda tek bir satın alma işlemi gerçekleştiren ve bu satın alma işleminin, dönem sonundan itibaren [dated] ile [Before] arası günden daha az bir süre önce gerçekleştiği müşteriler.'");
		Values.Insert("dated", dated);
		Values.Insert("Before", Before);	
	ElsIf Segment = "WP" Then 
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng tiềm năng không hoạt động';
													|ru = 'Засыпающие перспективные клиенты';
													|en = 'Sleepy prospective customers'; fa = 'Sleepy prospective customers';
													|it = 'Clienti potenziali inattivi';
													|pl = 'Zasypiające perspektywiczni klienci';
													|tr = 'Uykuya dalan uzun vadeli müşteriler'");
		Color = New Color(255, 255, 148);
		Text = NStr("vi = 'Các khách hàng đã mua hàng vào cuối kỳ từ [PurchasesFrom] đến [PurchasesBefore], đồng thời lần mua hàng gần nhất diễn ra từ [dated] đến [Before] ngày trước khi kết thúc kỳ.';
					|ru = 'Клиенты, совершившие на конец периода от [PurchasesFrom] до [PurchasesBefore] покупок, причём последняя покупка состоялась от [dated] до [Before] дн. назад, считая с конца периода.';
					|en = 'Customers who made from [PurchasesFrom] to [PurchasesBefore] purchases as of the period end, where the last purchase took place from [dated] to [Before] days ago, counting from the period end.'; fa = 'Customers who made from [PurchasesFrom] to [PurchasesBefore] purchases as of the period end, where the last purchase took place from [dated] to [Before] days ago, counting from the period end.';
					|it = 'Clienti che alla fine del periodo hanno realizzato da [PurchasesFrom] a [PurchasesBefore] acquisti, di cui l''ultimo è stato effettuato da [dated] a [Before] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu od [PurchasesFrom] do [PurchasesBefore] wykonali zakupów, przy tym ostatni zakup odbył się od [dated] do [Before] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda [PurchasesFrom] ile [PurchasesBefore] arası satın alma işlemi gerçekleştiren ve son satın alma işleminin, dönem sonundan itibaren [dated] ile [Before] arası günden daha az bir süre önce gerçekleştiği müşteriler.'");
		Values.Insert("dated", dated);
		Values.Insert("Before", Before);
		Values.Insert("PurchasesFrom", PurchasesFrom);
		Values.Insert("PurchasesBefore", PurchasesBefore);
	ElsIf Segment = "ZV_" Then 
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng trung thành không hoạt động';
													|ru = 'Засыпающие верные клиенты';
													|en = 'Sleepy loyal customers'; fa = 'Sleepy loyal customers';
													|it = 'Clienti reali inattivi';
													|pl = 'Zasypiające wierni klienci';
													|tr = 'Uykuya dalan bağlı müşteriler'");
		Color = New Color(255, 255, 90);
		Values.Insert("Before", Before);
		Values.Insert("dated", dated);
		Values.Insert("Purchases", Purchases);
		Text = NStr("vi = 'Các khách hàng đã thực hiện hơn [Purchases] lần mua hàng vào cuối kỳ, đồng thời lần mua hàng gần nhất diễn ra từ [dated] đến [Before] ngày trước khi kết thúc kỳ.';
					|ru = 'Клиенты, совершившие на конец периода более [Purchases] покупок, причём последняя покупка состоялась от [dated] до [Before] дн. назад, считая с конца периода.';
					|en = 'Customers who made more that [Purchases] purchases as of the period end, where the last purchase took place from [dated] to [Before] days ago, counting from the period end.'; fa = 'Customers who made more that [Purchases] purchases as of the period end, where the last purchase took place from [dated] to [Before] days ago, counting from the period end.';
					|it = 'Clienti che hanno realizzato più di [Purchases] acquisti alla fine del periodo, di cui l''ultimo acquisto è stato effettuato da [dated] a [Before] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu wykonali ponad [Purchases] zakupów, przy tym ostatni zakup odbył się od [dated] do [Before] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda [Purchases] üstü satın alma işlemi gerçekleştiren ve son satın alma işleminin, dönem sonundan itibaren [dated] ile [Before] arası günden daha az bir süre önce gerçekleştiği müşteriler.'");	
	
	ElsIf Segment = "SN" Then     
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng mới không hoạt động';
													|ru = 'Спящие новые клиенты';
													|en = 'Sleeping new customers'; fa = 'Sleeping new customers';
													|it = 'Clienti nuovi dormienti';
													|pl = 'Śpiące nowi klienci';
													|tr = 'Uyuyan yeni müşteriler'");
		Color = New Color(255, 205, 205);
		Values.Insert("dated", dated);
		Text = NStr("vi = 'Các khách hàng đã thực hiện mua hàng một lần duy nhất vào cuối kỳ, đồng thời lần mua hàng diễn ra hơn [dated] ngày trước khi kết thúc kỳ.';
					|ru = 'Клиенты, совершившие на конец периода единственную покупку, причём эта покупка состоялась более [dated] дн. назад, считая с конца периода.';
					|en = 'Customers who made a single purchase as of the period end, where this purchase took place more than [dated] days ago, counting from the period end.'; fa = 'Customers who made a single purchase as of the period end, where this purchase took place more than [dated] days ago, counting from the period end.';
					|it = 'Clienti che alla fine del periodo hanno realizzato un solo acquisto, effettuato più di [dated] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu wykonali jedyny zakup, przy tym ten zakup odbył się ponad [dated] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda tek bir satın alma işlemi gerçekleştiren ve bu satın alma işleminin, dönem sonundan itibaren [dated] günden daha fazla bir süre önce gerçekleştiği müşteriler.'");
	ElsIf Segment = "SP" Then 
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng tiềm năng không hoạt động';
													|ru = 'Спящие перспективные клиенты';
													|en = 'Sleeping prospective customers'; fa = 'Sleeping prospective customers';
													|it = 'Clienti potenziali dormienti';
													|pl = 'Śpiące perspektywiczni klienci';
													|tr = 'Uyuyan uzun vadeli müşteriler'");
		Color = New Color(255, 148, 148);
		Values.Insert("PurchasesFrom", PurchasesFrom);
		Values.Insert("PurchasesBefore", PurchasesBefore);
		Values.Insert("dated", dated);
		Text = NStr("vi = 'Các khách hàng đã thực hiện từ [PurchasesFrom] đến [PurchasesBefore] lần mua hàng vào cuối kỳ, đồng thời lần mua hàng gần nhất diễn ra hơn [dated] ngày trước khi kết thúc kỳ.';
					|ru = 'Клиенты, совершившие на конец периода от [PurchasesFrom] до [PurchasesBefore] покупок, причем последняя покупка состоялась более [dated] дн. назад, считая с конца периода.';
					|en = 'Customers who made from [PurchasesFrom] to [PurchasesBefore] purchases as of the period end, where the last purchase took place more than [dated] days ago, counting from the period end.'; fa = 'Customers who made from [PurchasesFrom] to [PurchasesBefore] purchases as of the period end, where the last purchase took place more than [dated] days ago, counting from the period end.';
					|it = 'Clienti che alla fine del periodo hanno realizzato da [PurchasesFrom] a [PurchasesBefore] acquisti, di cui l''ultimo è stato effettuato più di [dated] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu od [PurchasesFrom] do [PurchasesBefore] wykonali zakupów, przy tym ostatni zakup odbył się ponad [dated] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda [PurchasesFrom] ile [PurchasesBefore] arasın satın alma işlemi gerçekleştiren ve son satın alma işleminin, dönem sonundan itibaren [dated] günden daha fazla bir süre önce gerçekleştiği müşteriler.'");
	ElsIf Segment = "SV" Then     
		SectionHeader.Parameters.SegmentName_ = NStr("vi = 'Khách hàng trung thành không hoạt động';
													|ru = 'Спящие верные клиенты';
													|en = 'Sleeping loyal customers'; fa = 'Sleeping loyal customers';
													|it = 'Clienti reali dormienti';
													|pl = 'Śpiące wierni klienci';
													|tr = 'Uyuyan bağlı müşteriler'");
		Color = New Color(255, 90, 90);
		Values.Insert("Purchases",Purchases);
		Values.Insert("dated", dated);
		Values.Insert("Before", Before);
		Text = NStr("vi = 'Các khách hàng đã mua hàng hơn [Purchases] lần vào cuối kỳ, đồng thời lần mua hàng gần nhất diễn ra hơn [dated] ngày trước khi kết thúc kỳ.';
					|ru = 'Клиенты, совершившие на конец периода более [Purchases] покупок,причём последняя покупка состоялась более [dated] дн. назад, считая с конца периода.';
					|en = 'Customers who made not more that [Purchases] purchases as of the period end, where the last purchase took place more than [dated] days ago, counting from the period end.'; fa = 'Customers who made not more that [Purchases] purchases as of the period end, where the last purchase took place more than [dated] days ago, counting from the period end.';
					|it = 'Clienti che hanno realizzato più di [Purchases] acquisti alla fine del periodo, di cui l''ultimo acquisto è stato effettuato più di [dated] giorni dalla fine del periodo.';
					|pl = 'Klienci, którzy na koniec okresu wykonali ponad [Purchases] zakupów, przy tym ostatni zakup odbył się więcej niż [dated] dni temu, licząc od końca okresu.';
					|tr = 'Dönem sonunda [Purchases] üstü satın alma işlemi gerçekleştiren ve bu satın alma işleminin, dönem sonundan itibaren [dated] günden daha fazla bir süre önce gerçekleştiği müşteriler.'");
	EndIf;
	
	AreaDescription_.Parameters.SegmentDescription = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
	Result.Clear();	
	Result.Put(SectionHeader);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
	Result.Put(AreaDescription_);
	Result.Area("R5C1").Picture = Picture;
	Result.Area("Header").BackColor = Color;

	//Checking for the fullness of selections
	If PeriodOfUse Or OrganizationUsage Or ManagerUsage
		Or PurchaseAmountUsage Or CustomerSegmentUsage
		Or ItemSegmentUsage Or NomenclatureUsage Then
		AreaParameters = Template.GetArea("RegionParameters");
	    Result.Put(AreaParameters);
	EndIf;
		
	If PeriodOfUse Then
		AreaPeriod = Template.GetArea("RegionPeriod");
		DateTemplate = NStr("vi = 'DF=%Couples1%';
							|ru = 'ДФ=%Couples1%';
							|en = 'DF=%Couples1%'; fa = 'DF=%Couples1%';
							|it = 'DF=%Couples1%';
							|pl = 'DF=%Couples1%';
							|tr = 'DF=%Couples1%'");
		DateTemplate = StrReplace(DateTemplate, "%Couples1%", "dd.MM.yyyy");
		Values.Insert("StartDate", Format(StartDate,DateTemplate));
		Values.Insert("EndDate", Format(EndDate,DateTemplate));
		Text = NStr("vi = '[StartDate] - [EndDate]';
					|ru = '[StartDate] - [EndDate]';
					|en = '[StartDate] - [EndDate]'; fa = '[StartDate] - [EndDate]';
					|it = '[StartDate] - [EndDate]';
					|pl = '[StartDate] - [EndDate]';
					|tr = '[StartDate] - [EndDate]'");
		AreaPeriod.Parameters.Period = StringFunctionsClientServer.InsertParametersIntoString(Text,Values); 
		Result.Put(AreaPeriod);
	EndIf;
	
	If OrganizationUsage Then
		AreaOrganization = Template.GetArea("RegionalOrganization");
		AreaOrganization.Parameters.Organization = Organization; 
		Result.Put(AreaOrganization);
	EndIf;

	If ManagerUsage Then
		AreaManager = Template.GetArea("RegionManager");
		AreaManager.Parameters.Manager = Manager; 
		Result.Put(AreaManager);
	EndIf;
	
	If PurchaseAmountUsage Then
		AreaAmountFrom = Template.GetArea("OblAmountFrom");
		Values.Insert("AmountFrom", AmountOfPurchases);
		Text = NStr("vi = '[AmountFrom] [Currency].';
					|ru = '[AmountFrom] [Currency].';
					|en = '[AmountFrom] [Currency].'; fa = '[AmountFrom] [Currency].';
					|it = '[AmountFrom] [Currency].';
					|pl = '[AmountFrom] [Currency].';
					|tr = '[AmountFrom] [Currency].'");
		AreaAmountFrom.Parameters.AmountOfPurchasesFrom = StringFunctionsClientServer.InsertParametersIntoString(Text,Values); 
		Result.Put(AreaAmountFrom);
	EndIf;
	
	If CustomerSegmentUsage Then
		CustomerSegmentArea = Template.GetArea("OBLCustomerSegment");
		CustomerSegmentArea.Parameters.CustomerSegment = CustomerSegment ; 
		Result.Put(CustomerSegmentArea);
	EndIf;
	
	If ItemSegmentUsage Then
		ProductSegmentArea = Template.GetArea("OBLProductSegment");
		ProductSegmentArea.Parameters.ProductSegment = ProductSegment; 
		Result.Put(ProductSegmentArea);
	EndIf;
	
	If NomenclatureUsage Then
		ItemsArea = Template.GetArea("RegionalProducts");
		ItemsArea.Parameters.Products = Products; 
		Result.Put(ItemsArea);
	EndIf;
	
	//Output the table header
	Area_TableHeader = Template.GetArea("TableHeader_");
	Result.Put(Area_TableHeader);
	
	Text = NStr("vi = 'Số tiền mua hàng trong kỳ, [Currency]';
				|ru = 'Сумма покупок за период, [Currency]';
				|en = 'Amount of purchases in period, [Currency]'; fa = 'Amount of purchases in period, [Currency]';
				|it = 'Importo degli acquisti per il periodo, [Currency]';
				|pl = 'Wartość zakupów za okres, [Currency]';
				|tr = 'Döneme ait satın alma tutarı, [Currency]'");	
	Result.Area("Sum").Text =StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
	
	Text = NStr("vi = 'Số tiền mua hàng vào cuối kỳ trong toàn thời gian, [Currency]';
				|ru = 'Сумма покупок на конец периода за всё время, [Currency]';
				|en = 'Amount of purchases at the period end for all time, [Currency]'; fa = 'Amount of purchases at the period end for all time, [Currency]';
				|it = 'Il totale degli acquisti alla fine del periodo per tutto il periodo, [Currency]';
				|pl = 'Wartość zakupów na koniec okresu za cały czas, [Currency]';
				|tr = 'Tüm zamanlar için dönem sonundaki satın alma tutarı, [Currency]'");	
	Result.Area("AmountTotal").Text =StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
	
	AreaRow = Template.GetArea("String");
	
	//filling in the decryption parameters
	SelectionParameterNames = 
		"Organization,OrganizationUsage,
		|Manager,ManagerUsage,
		|StartDate,EndDate,PeriodOfUse,
		|Products,NomenclatureUsage,,
		|CustomerSegment,CustomerSegmentUsage,
		|ProductSegment,ItemSegmentUsage,
		|AmountOfPurchases,PurchaseAmountUsage,
		|PurchasesArePromisingUpTo,ActiveUpTo,FallingAsleepBefore,
		|ActiveProspectiveUpTo,FallingAsleepPromisingUpTo,
		|ActiveLoyalTo,FallingAsleepFaithfulTo,PurchasesAreCorrect";

	Filters = New Structure(SelectionParameterNames);
	FillPropertyValues(Filters, ThisForm);
	
	//Fill in the table
	ListOfClients = ResultList.ListOfClients;
	For Each String In ListOfClients Do
		AreaRow.Parameters.Client = String.Client.DescriptionFull;
		DecryptionTo = New Structure ("Client",String.Client);
		AreaRow.Parameters.RClient = DecryptionTo;
		
		AreaRow.Parameters.ClientManager = String.ClientManager;
		DecodingM = New Structure ("Manager",String.ClientManager);
		AreaRow.Parameters.PManager = DecodingM;

		AreaRow.Parameters.DateOfPurchase = String.DateOfPurchase;
		
		DecryptionOfP = New Structure ("ColvoShopping",String.Client);
		DecryptionOfP.Insert("Filter",Filters);
		AreaRow.Parameters.ColvoShopping = String.ColvoShopping;
		AreaRow.Parameters.pColvoShopping = DecryptionOfP;
		
		DecryptionOfPAll = New Structure ("ColvoPurchasesTotal",String.Client);
		DecryptionOfPAll.Insert("Filter",Filters);
		AreaRow.Parameters.ColvoPurchasesTotal = String.ColvoPurchasesTotal;
		AreaRow.Parameters.pColvoPurchasesTotal = DecryptionOfPAll;
		
		AreaRow.Parameters.AmountOfPurchases = String.AmountOfPurchases;
		AreaRow.Parameters.TotalPurchases = String.TotalPurchases;
		AreaRow.Parameters.EAddress = String.EAddress;
		AreaRow.Parameters.Phone = String.Phone;
		Result.Put(AreaRow);
	EndDo;

EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;
	If Details.Property("Client") Then
		ShowValue(,Details.Client);
	ElsIf Details.Property("Manager") Then
		ShowValue(,Details.Manager);
	ElsIf Details.Property("ColvoShopping") Then 
		Details.Insert("TypeOfPurchase","ColvoShopping");
		OpenForm("Report.RepeatedSales.Form.ListFormPurchases",Details,ThisForm);
	ElsIf Details.Property("ColvoPurchasesTotal") Then
		Details.Insert("TypeOfPurchase","ColvoPurchasesTotal");
		OpenForm("Report.RepeatedSales.Form.ListFormPurchases",Details,ThisForm);
	EndIf;
	
EndProcedure

#EndRegion
