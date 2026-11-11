//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.RepeatedSales);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích và tổ chức bán hàng ổn định theo cơ sở khách hàng thường xuyên.
	    |Đề xuất kịp thời sẽ có lợi cho khách hàng nào?';
	    |ru = 'Анализ и организация стабильных продаж по постоянной клиентской базе.
	    |Каким клиентами будет выгодно сделать своевременное предложение?';
	    |en = 'Analyze and ensure stable sales with a permanent customer base.
	    |Check customers to make a timely offer.'; fa = 'Analyze and ensure stable sales with a permanent customer base.
	    |Check customers to make a timely offer.';
	    |it = 'Анализ и организация стабильных продаж по постоянной клиентской базе.
	    |Каким клиентами будет выгодно сделать своевременное предложение?';
	    |pl = 'Analiza i organizacja stałej ilości sprzedaż w stałej bazie klienckiej.
	    |Jakim klientom będzie korzystnie zrobić aktualną ofertę?';
	    |tr = 'Kalıcı bir müşteri tabanı için istikrarlı satışların analizi ve organizasyonu.
	    |Zamanında teklif vermek hangi müşterilere fayda sağlar?'");
	OptionDetails.SearchSettings.FieldDescriptions = NStr("vi = 'Khách hàng
		|Khách hàng
		|Phân khúc
		|Doanh thu
		|Tiềm năng
		|Đang hoạt động
		|Dự tính
		|Dự tính và đã mất
		|Mới
		|Tiềm năng
		|Trung thành
		|Điện thoại
		|Bán hàng';
		|ru = 'Клиенты
		|Клиент
		|Сегмент
		|Выручка
		|Потенциал
		|Активные
		|Засыпающие
		|Спящие и потерянные
		|Новые
		|Перспективные
		|Верные
		|Телефон
		|Продажи';
		|en = 'Customers
		|Customer
		|Segment
		|Revenue
		|Potential
		|Active
		|Sleepy
		|Sleeping and lost
		|New
		|Prospective
		|Loyal
		|Phone
		|Sales'; fa = 'Customers
		|Customer
		|Segment
		|Revenue
		|Potential
		|Active
		|Sleepy
		|Sleeping and lost
		|New
		|Prospective
		|Loyal
		|Phone
		|Sales';
		|it = 'Клиенты
		|Клиент
		|Сегмент
		|Выручка
		|Потенциал
		|Активные
		|Засыпающие
		|Спящие и потерянные
		|Новые
		|Перспективные
		|Верные
		|Телефон
		|Продажи';
		|pl = 'Klienci
		|Klient
		|Segment
		|Utarg
		|Potencjał
		|Aktywni
		|Zasypiające
		|Śpiące i stracone
		|Nowi
		|Perspektywni
		|Werni
		|Telefon
		|Sprzedaż';
		|tr = 'Müşteriler
		|Müşteri
		|Segment
		|Gelir
		|Potansiyel
		|Aktif
		|Uykuya dalan
		|Uyuyan ve kaybedilen
		|Yeni
		|Uzun vadeli
		|Sadık
		|Telefon
		|Satışlar'");
	OptionDetails.SearchSettings.FilterParameterDescriptions = NStr("vi = 'Ngày bắt đầu
		|Ngày kết thúc
		|Kỳ
		|Doanh nghiệp
		|Người quản lý
		|Số tiền mua hàng từ
		|Phân khúc khách hàng
		|Phân khúc mặt hàng
		|Mặt hàng';
		|ru = 'Дата начала
		|Дата окончания
		|Период
		|Организация
		|Менеджер
		|Сумма покупки от
		|Сегмент клиентов
		|Сегмент номенклатуры
		|Номенклатура';
		|en = 'Start date
		|End date
		|Period
		|Company
		|Manager
		|Purchase amount from
		|Customer segment
		|Inventory segment
		|Products'; fa = 'Start date
		|End date
		|Period
		|Company
		|Manager
		|Purchase amount from
		|Customer segment
		|Inventory segment
		|Products';
		|it = 'Дата начала
		|Дата окончания
		|Период
		|Организация
		|Менеджер
		|Сумма покупки от
		|Сегмент клиентов
		|Сегмент номенклатуры
		|Номенклатура';
		|pl = 'Data początku
		|Data zakończenia
		|Okres
		|Firam
		|Menedżer
		|Wartość zakupu od
		|Segment klientów
		|Segment pozycji
		|Pozycja';
		|tr = 'Başlangıç tarihi
		|Bitiş tarihi
		|Dönem
		|İş yeri
		|Yönetici
		|Alış tutarı
		|Müşteri segmenti
		|Öğe segmenti
		|Öğe'");
	Subsystem = Metadata.FindByFullName("Subsystem.CRMAndMarketing.Subsystem.CustomerBaseAnalysis");
	OptionDetails.Location.Insert(Subsystem);
	
EndProcedure

#EndRegion

#EndRegion

Procedure FillCustomerSegments(Filters,StorageAddress) Export

	Query = New Query();
	Query.Text = "SELECT ALLOWED DISTINCT
	               |	Segments.Partner AS Partner
	               |INTO SelectionByPartnerSegment
	               |FROM
	               |	InformationRegister.SegmentPartners AS Segments
	               |WHERE
	               |	Segments.Segment = &CustomerSegment
	               |
	               |INDEX BY
	               |	Partner
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT ALLOWED DISTINCT
	               |	Segments.Products AS Products
	               |INTO SelectionByProductSegment
	               |FROM
	               |	InformationRegister.SegmentProducts AS Segments
	               |WHERE
	               |	Segments.Segment = &ProductSegment
	               |
	               |INDEX BY
	               |	Products
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT ALLOWED
	               |	COUNT(DISTINCT Sales.Recorder) AS Recorder,
	               |	Sales.AccountingDimensionByPartners.Partner AS Partner,
	               |	MAX(Sales.SecondPeriod) AS DateOfLastPurchase,
	               |	MIN(Sales.SecondPeriod) AS DateOfFirstPurchase
	               |FROM
	               |	AccumulationRegister.RevenueAndCOGS.Turnovers(
	               |			&BeginOfPeriod,
	               |			&EndOfPeriod,
	               |			Auto,
	               |			(NOT &ProductSelectionIsUsed_
	               |				OR ItemsLocationAttributes.Products = &Products)
	               |				AND (NOT &FilterByPartnerSegmentIsUsed
	               |					OR AccountingDimensionByPartners.Partner IN
	               |						(SELECT
	               |							SelectionByPartnerSegment.Partner
	               |						FROM
	               |							SelectionByPartnerSegment))
	               |				AND (NOT &FilterByProductSegmentIsUsed
	               |					OR ItemsLocationAttributes.Products IN
	               |						(SELECT
	               |							SelectionByProductSegment.Products
	               |						FROM
	               |							SelectionByProductSegment))
	               |				AND (NOT &ManagerSelectionIsUsed
	               |					OR Manager = &Manager)) AS Sales
	               |		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	               |		ON Sales.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	               |WHERE
	               |	(NOT &OrganizationSelectionIsUsed
	               |			OR DimensionKeysOfAccountingByPartners.Organization = &Organization)
	               |	AND (NOT &SelectionBasedOnAmountOfPurchasesIsUsed
	               |			OR Sales.RevenueAmountTurnover > &AmountOfPurchases)
	               |	AND Sales.RevenueAmountTurnover > 0
	               |GROUP BY
	               |	Sales.AccountingDimensionByPartners.Partner";

	//Installing selections
	Query.SetParameter("ProductSelectionIsUsed_",Filters.NomenclatureUsage);
	Query.SetParameter("OrganizationSelectionIsUsed",Filters.OrganizationUsage);
	Query.SetParameter("SelectionBasedOnAmountOfPurchasesIsUsed",Filters.PurchaseAmountUsage);
	Query.SetParameter("FilterByPartnerSegmentIsUsed",Filters.CustomerSegmentUsage);
	Query.SetParameter("FilterByProductSegmentIsUsed",Filters.ItemSegmentUsage);
	Query.SetParameter("ManagerSelectionIsUsed",Filters.ManagerUsage);
	Query.SetParameter("CustomerSegment",Filters.CustomerSegment);
	Query.SetParameter("ProductSegment",Filters.ProductSegment);
	Query.SetParameter("Products",Filters.Products);
	Query.SetParameter("Organization",Filters.Organization);
	Query.SetParameter("AmountOfPurchases",Filters.AmountOfPurchases);
	Query.SetParameter("Manager",Filters.Manager);
	
	Query.SetParameter("BeginOfPeriod",BegOfDay(Date('00010101000000')));
	Query.SetParameter("EndOfPeriod",EndOfDay(CurrentSessionDate()));
	
	Selection = Query.Execute().Select();
		
	FirstPurchase = New ValueList;

	//Counting the first purchases
	While Selection.Next() Do			
		If Filters.PeriodOfUse = True Then
			//If the period is used, we check whether the dates of the customer's very first purchase are included in the period
			If Selection.DateOfFirstPurchase >= BegOfDay(Filters.BeginningDateOfPeriod) And Selection.DateOfFirstPurchase <= EndOfDay(Filters.EndingDateOfPeriod) Then
					FirstPurchase.Add(Selection.Partner, Selection.Partner);
				EndIf;
			Else
				//If the period is not used, then each purchase is the first
				FirstPurchase.Add(Selection.Partner, Selection.Partner);	
			EndIf;
	EndDo;
	
	ActiveNewBeginnings = New ValueList; 
	FallingAsleepNewBeginnings = New ValueList;
	SleepingNewBeginnings = New ValueList;
		
	ActivePromisingCompanies = New ValueList;
	FallingAsleepPromisingStart = New ValueList;
	SleepingProspectsStartList = New ValueList;
		
	ActiveLoyalFriends = New ValueList;
	FallingAsleepFaithfulBeginnings = New ValueList;
	SleepingFaithfulListBeginning = New ValueList;
	
	ActiveNew =  New ValueList;
	FallingAsleepNew = New ValueList;
	SleepingNew =  New ValueList;
	
	RevenueNew = 0;
	RevenueProspects = 0;
	RevenueFaithful = 0;
	
	ActiveProspects = New ValueList;
	FallingAsleepProspects = New ValueList;
	SleepingProspectsList = New ValueList;
	
	ActiveFaithful = New ValueList;
	SleepingFaithful_ = New ValueList;
	SleepingFaithfulList = New ValueList;
	
	APTransition = 0;
	TransitionAB = 0;	
	ZNTransition = 0;
	TransitionCH = 0;	
	ZNAPTransition = 0;
	SNAPTransition = 0;
	POTransition = 0;
	SPTransition = 0;
	PoTransition_ = 0;
	SPAPTransition = 0;
	ZPAVTransition = 0;
	SPAVTransition = 0;
	ZvTransition = 0;
	SVTransition = 0;
	ZVAVTransition = 0;
	SVAVTransition = 0;
	
	//If the period is used, we set the interval before the period and count how many customers there were
	If Filters.PeriodOfUse = True Then
		
		Query.Text = "SELECT ALLOWED DISTINCT
		               |	Segments.Partner AS Partner
		               |INTO SelectionByPartnerSegment
		               |FROM
		               |	InformationRegister.SegmentPartners AS Segments
		               |WHERE
		               |	Segments.Segment = &CustomerSegment
		               |
		               |INDEX BY
		               |	Partner
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |SELECT ALLOWED DISTINCT
		               |	Segments.Products AS Products
		               |INTO SelectionByProductSegment
		               |FROM
		               |	InformationRegister.SegmentProducts AS Segments
		               |WHERE
		               |	Segments.Segment = &ProductSegment
		               |
		               |INDEX BY
		               |	Products
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |SELECT ALLOWED DISTINCT
		               |	Sales.RevenueAmountTurnover AS RevenueAmountTurnover,
		               |	Sales.Recorder AS Recorder,
		               |	Sales.AccountingDimensionByPartners.Partner AS Partner,
		               |	Sales.SecondPeriod AS DateOfLastPurchase,
		               |	Sales.SecondPeriod AS DateOfFirstPurchase,
		               |	Sales.MinutePeriod AS CurPurchaseDate,
		               |	Sales.Warehouse AS Warehouse
		               |FROM
		               |	AccumulationRegister.RevenueAndCOGS.Turnovers(
		               |			&BeginOfPeriod,
		               |			&EndOfPeriod,
		               |			Auto,
		               |			(NOT &ProductSelectionIsUsed_
		               |				OR ItemsLocationAttributes.Products = &Products)
		               |				AND (NOT &FilterByPartnerSegmentIsUsed
		               |					OR AccountingDimensionByPartners.Partner IN
		               |						(SELECT
		               |							SelectionByPartnerSegment.Partner
		               |						FROM
		               |							SelectionByPartnerSegment))
		               |				AND (NOT &FilterByProductSegmentIsUsed
		               |					OR ItemsLocationAttributes.Products IN
		               |						(SELECT
		               |							SelectionByProductSegment.Products
		               |						FROM
		               |							SelectionByProductSegment))
		               |				AND (NOT &ManagerSelectionIsUsed
		               |					OR Manager = &Manager)) AS Sales
		               |		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		               |		ON Sales.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		               |WHERE
		               |	(NOT &OrganizationSelectionIsUsed
		               |			OR DimensionKeysOfAccountingByPartners.Organization = &Organization)
		               |	AND (NOT &SelectionBasedOnAmountOfPurchasesIsUsed
		               |			OR Sales.RevenueAmountTurnover > &AmountOfPurchases)
		               |	AND Sales.RevenueAmountTurnover > 0
		               |ORDER BY
		               |	CurPurchaseDate
		               |TOTALS
		               |	SUM(RevenueAmountTurnover),
		               |	COUNT(DISTINCT Recorder),
		               |	MAX(DateOfLastPurchase),
		               |	MIN(DateOfFirstPurchase)
		               |BY
		               |	Partner";

		Query.SetParameter("BeginOfPeriod",BegOfDay(Date('00010101000000')));
		Query.SetParameter("EndOfPeriod",EndOfDay(Filters.BeginningDateOfPeriod) - 60 * 60 * 24);
		Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
		While Selection.Next() Do
								
			DaysFromPurchase = (BegOfDay(Filters.BeginningDateOfPeriod)-(BegOfDay(Selection.DateOfLastPurchase)))/(60 * 60 * 24);
			
			//New_Items
			If Selection.Recorder = 1 Then
								
				//We fill in the active ones
				If DaysFromPurchase < Filters.ActiveUpTo Then
					ActiveNewBeginnings.Add(Selection.Partner, Selection.Partner);
				EndIf;
								
				//Filling in the falling asleep
				If DaysFromPurchase >= Filters.ActiveUpTo And DaysFromPurchase <= Filters.FallingAsleepBefore Then
					FallingAsleepNewBeginnings.Add(Selection.Partner,Selection.Partner);
				EndIf;
						
				//Filling in the sleepers
				If DaysFromPurchase >  Filters.FallingAsleepBefore Then
					SleepingNewBeginnings.Add(Selection.Partner, Selection.Partner);
				EndIf;

			//Promising
			ElsIf Selection.Recorder >= 2 And Selection.Recorder <= Filters.PurchasesArePromisingUpTo Then
								
				//We fill in the active ones
				If DaysFromPurchase < Filters.ActiveProspectiveUpTo Then
					ActivePromisingCompanies.Add(Selection.Partner, Selection.Partner);
				EndIf;
								
				//Filling in the falling asleep
				If DaysFromPurchase >=  Filters.ActiveProspectiveUpTo And DaysFromPurchase <= Filters.FallingAsleepPromisingUpTo Then
					FallingAsleepPromisingStart.Add(Selection.Partner,Selection.Partner);
				EndIf;
								
				//Filling in the sleepers
				If DaysFromPurchase >  Filters.FallingAsleepPromisingUpTo Then
					SleepingProspectsStartList.Add(Selection.Partner, Selection.Partner);
				EndIf;
								
			//Right	
			ElsIf Selection.Recorder >=  Filters.PurchasesArePromisingUpTo Then
								
				//We fill in the active ones
				If DaysFromPurchase <  Filters.ActiveLoyalTo Then
					ActiveLoyalFriends.Add(Selection.Partner,Selection.Partner);
				EndIf;
							
				//Filling in the falling asleep
				If DaysFromPurchase >= Filters.ActiveLoyalTo And DaysFromPurchase <= Filters.FallingAsleepFaithfulTo Then
					FallingAsleepFaithfulBeginnings.Add(Selection.Partner,Selection.Partner);
				EndIf;
							
				//Filling in the sleepers
				If DaysFromPurchase >  Filters.FallingAsleepFaithfulTo Then
					SleepingFaithfulListBeginning.Add(Selection.Partner,Selection.Partner);
				EndIf;
						
			EndIf;	
		EndDo;	
	
		//If the period is used, we set the dates of the period and count the transitions
		Query.SetParameter("BeginOfPeriod",BegOfDay(Filters.BeginningDateOfPeriod));
		Query.SetParameter("EndOfPeriod",EndOfDay(Filters.EndingDateOfPeriod));
		
		SamplePeriod = Query.Execute().Select(QueryResultIteration.ByGroups);
				
		//We count movements and clients
		//WE GO STRAIGHT - TO CUSTOMERS WITH PURCHASES MADE DURING THE SPECIFIED PERIOD
		//(WITH A CHECK ON HOW MANY PURCHASES THERE WERE BEFORE) 
		While SamplePeriod.Next() Do
											
				//WE DETERMINE HOW MANY PURCHASES THERE WERE
				Selection.Reset();
				If Selection.FindNext(New Structure("Partner",SamplePeriod.Partner)) Then
					ThereWasNoColvo = Selection.Recorder;
					ColvoShopping = Selection.Recorder;
					//MEMORIZE THE DATE OF THE LAST PURCHASE
					DateOfLastPurchase_ = Selection.DateOfLastPurchase;
					DaysFromDateOfPurchase = (BegOfDay(Filters.BeginningDateOfPeriod)-(BegOfDay(DateOfLastPurchase_)))/(60 * 60 * 24); 
				Else
					//IF THEY DIDN'T FIND IT, THEN THERE WERE NO PURCHASES, THE DATE IS EMPTY
					ThereWasNoColvo = 0;
					ColvoShopping = 0;
					DateOfLastPurchase_ = "";
				EndIf;
					
				//WE WILL REMEMBER THE REGISTRARS SO AS NOT TO REPEAT OURSELVES
				PastRegistrars = New Map;
					
				SamplePeriodPurchase = SamplePeriod.Select(QueryResultIteration.ByGroups);
				While SamplePeriodPurchase.Next() Do
						
					//WE CHECK THE REGISTRAR SO AS NOT TO REPEAT
					If PastRegistrars[SamplePeriodPurchase.Recorder] = True Then
						Continue;
					EndIf;

					PastRegistrars[SamplePeriodPurchase.Recorder] = True;
						
					If DateOfLastPurchase_ = "" Then
						DateOfLastPurchase_ = SamplePeriodPurchase.CurPurchaseDate;
					EndIf;
					
					ColvoShopping = ColvoShopping+1;
						
					DaysFromPurchase = (BegOfDay(Filters.EndingDateOfPeriod)-(BegOfDay(SamplePeriodPurchase.CurPurchaseDate)))/ (60 * 60 * 24); 						
					DaysFromDateOfPurchase_ = (BegOfDay(Filters.EndingDateOfPeriod)-(BegOfDay(DateOfLastPurchase_)))/(60 * 60 * 24); 
						
					//IF THERE IS 1 PURCHASE (I.E. IN NEW ONES) 
					//, THEN WE CHECK WHETHER IT HAS GONE DOWN (HERE WE DO NOT CHECK THE PRE-PURCHASE BECAUSE THERE IS NONE)
					If ThereWasNoColvo = 0 And ColvoShopping = 1 Then						
						//WE CHECK WHETHER THEY HAVE GONE DOWN
						If DaysFromDateOfPurchase_ >= Filters.ActiveUpTo Then
							ZNTransition = ZNTransition+1;
							//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
							If DaysFromDateOfPurchase_ > Filters.FallingAsleepBefore Then
								CurSegment = "SN";
								TransitionCH = TransitionCH+1;
							Else
								CurSegment = "ZN";
							EndIf;
						Else
							CurSegment = "AN";
						EndIf;
					EndIf;
					
					//IF THERE WAS 1 PURCHASE AND IT BECAME MORE (I.E. IN NEW ONES) 
					//, THEN WE CHECK WHERE THEY LEFT FROM
					If ThereWasNoColvo = 1 And ColvoShopping > 1 Then						
						//IF YOU WERE IN THE AN, CHECK IF YOU WENT DOWN
						If DaysFromDateOfPurchase < Filters.ActiveUpTo Then
							//IF THERE ARE MORE DAYS FROM THE DATE OF PURCHASE THAN IT IS NECESSARY FOR AN, THEN DOWN
							If DaysFromDateOfPurchase_ >= Filters.ActiveUpTo Then
								ZNTransition = ZNTransition+1;
								//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
								If DaysFromDateOfPurchase_ > Filters.FallingAsleepBefore Then
									TransitionCH = TransitionCH+1;
									CurSegment = "SN";
								Else
									CurSegment = "ZN";
								EndIf;
							Else
								CurSegment = "AN";
							EndIf;
						//IF YOU WERE IN THE ZN, CHECK WHETHER YOU WENT DOWN	 
						ElsIf DaysFromDateOfPurchase >= Filters.ActiveUpTo And DaysFromDateOfPurchase <= Filters.FallingAsleepBefore  Then
							//IF THE DAYS SINCE THE LAST PURCHASE ARE MORE THAN NECESSARY FOR ZN, THEN DOWN
							If DaysFromDateOfPurchase_ > Filters.FallingAsleepBefore Then
							  	TransitionCH = TransitionCH+1;
								CurSegment = "SN";	 
							Else
								CurSegment = "ZN";
							EndIf;
						//IF YOU WERE IN A DREAM, JUST CONFIRM IT	
						Else
							CurSegment = "SN";
						EndIf;
						ThereWasNoColvo =0;
					EndIf;
					
					//IF THERE IS MORE THAN ONE PURCHASE, BUT NO MORE THAN IN PERSPECT (I.E. THE CUSTOMER HAS REMAINED IN PERSPECT FOR THE TIME BEING)
					//SO WE CHECK WHERE WE ARE GOING BY PERSPECT
					If ColvoShopping >= 2 And ColvoShopping <=  Filters.PurchasesArePromisingUpTo Then 
						
						//IF THERE ARE 2 PURCHASES SO FAR, THEN WE CHECK WHERE WE WERE IN THE NEW ONES AND WHERE WE GO ACCORDING TO PERSPECT
						If ColvoShopping = 2 Then		
							//Let's find out where we switched from 
							//IF YOU WERE IN AN AP TRANSITION
							If DaysFromDateOfPurchase_ < Filters.ActiveUpTo Then 
								APTransition = APTransition+1;										
							//IF YOU WERE IN ZN , YOU KNOW
							ElsIf DaysFromDateOfPurchase_ >= Filters.ActiveUpTo And DaysFromDateOfPurchase_ <= Filters.FallingAsleepBefore Then
							    ZNAPTransition = ZNAPTransition+1;
							//IF YOU WERE IN A DREAM THEN THE TRANSITION SNAP
							ElsIf DaysFromDateOfPurchase_ > Filters.FallingAsleepBefore Then
							     SNAPTransition = SNAPTransition+1;
							EndIf;
								
							//IN ANY CASE, IF WE HAVE MOVED, WE FIND OURSELVES IN THE AP (AT THE TOP)AND FROM THERE ONLY THE WAY DOWN
							//CHECK IF IT WENT DOWN
							If DaysFromPurchase >= Filters.ActiveProspectiveUpTo Then
								POTransition = POTransition+1;
								//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
								If DaysFromPurchase > Filters.FallingAsleepPromisingUpTo Then
									CurSegment = "SP";
									SPTransition = SPTransition+1;
								Else
									CurSegment = "WP";
								EndIf;
							Else														
							CurSegment = "AP";
							EndIf;
									
						//IF THERE WERE 2 PURCHASES (OR MORE)AND IT BECAME MORE (I.E. THERE WERE 3 OF THEM AND REMAINED IN PERSP) 
						//SO WE CHECK WHERE WE WERE 
						ElsIf ThereWasNoColvo >= 2 And ColvoShopping > 2 Then						
								//IF YOU WERE IN THE AN, CHECK IF YOU WENT DOWN
								If DaysFromDateOfPurchase < Filters.ActiveProspectiveUpTo Then
									//IF THERE ARE MORE DAYS FROM THE DATE OF PURCHASE THAN IT IS NECESSARY FOR AN, THEN DOWN
									If DaysFromDateOfPurchase_ >= Filters.ActiveProspectiveUpTo Then
										POTransition = POTransition+1;
										//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
										If DaysFromDateOfPurchase_ > Filters.FallingAsleepPromisingUpTo Then
											SPTransition = SPTransition+1;
											CurSegment = "SP";
										Else
											CurSegment = "WP";
										EndIf;
									Else
										CurSegment = "AP";
									EndIf;
					 			//IF YOU WERE IN THE PO, WE CHECK WHETHER YOU WENT DOWN	 
								ElsIf DaysFromDateOfPurchase >= Filters.ActiveProspectiveUpTo And DaysFromDateOfPurchase_ <= Filters.FallingAsleepPromisingUpTo Then
									//IF THE DAYS SINCE THE LAST PURCHASE ARE MORE THAN NECESSARY FOR ZN, THEN DOWN
									If DaysFromDateOfPurchase_ > Filters.FallingAsleepPromisingUpTo Then
									  	SPTransition = SPTransition+1;
										CurSegment = "SP";	 
									Else
										CurSegment = "WP";
									EndIf;
								 //IF YOU WERE IN A JOINT VENTURE, JUST CONFIRM IT
								Else 
									CurSegment = "SP";
								EndIf;
								ThereWasNoColvo = 0;
						//IF THERE HAVE ALREADY BEEN MORE THAN 2 PURCHASES, THEN WE CHECK WHERE WE WERE AND WHERE WE GO ACCORDING TO PERSPECT	
						Else
							//Let's find out where we switched from 
							//IF YOU WERE IN THE AP, WE CHECK WHETHER YOU WENT DOWN
							If DaysFromDateOfPurchase_ < Filters.ActiveProspectiveUpTo Then
								//IF THE DAYS SINCE THE LAST PURCHASE ARE MORE THAN NECESSARY FOR THE AP THEN DOWN
								If DaysFromPurchase >= Filters.ActiveProspectiveUpTo  Then
						        	POTransition = POTransition+1;
									//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
									If DaysFromPurchase > Filters.FallingAsleepPromisingUpTo Then
										SPTransition = SPTransition+1;
										CurSegment = "SP";
									Else
										CurSegment = "WP";
									EndIf;
								EndIf;
							//IF YOU WERE IN THE PO, WE CHECK WHETHER YOU WENT DOWN OR UP	 
							ElsIf DaysFromDateOfPurchase_ >= Filters.ActiveProspectiveUpTo And DaysFromDateOfPurchase_ <=  Filters.FallingAsleepPromisingUpTo Then
								//IF THERE ARE MORE DAYS SINCE THE LAST PURCHASE THAN NECESSARY FOR THE PO, THEN DOWN
								If DaysFromPurchase > Filters.FallingAsleepPromisingUpTo Then
						        	SPTransition = SPTransition+1;
									CurSegment = "SP";
								//IF THE DAYS SINCE THE LAST PURCHASE ARE LESS THAN NECESSARY THAN NECESSARY FOR THE PO, THEN UP	 
								ElsIf DaysFromPurchase < Filters.ActiveProspectiveUpTo Then
								    PoTransition_ = PoTransition_ +1;
									CurSegment = "AP";
								EndIf;
							//IF THEY WERE IN THE BACK, WE CHECK WHETHER THEY WENT TO THE TOP		
							ElsIf DaysFromDateOfPurchase_ > Filters.FallingAsleepPromisingUpTo Then
								//IF THE DAYS FROM THE LAST PURCHASE ARE LESS THAN NECESSARY FOR THE JOINT VENTURE, THEN UP
								If DaysFromPurchase <= Filters.FallingAsleepPromisingUpTo Then
									SPAPTransition = SPAPTransition +1; 
									CurSegment = "WP";
									//CLARIFYING THE FINAL SEGMENT
									If DaysFromPurchase < Filters.ActiveProspectiveUpTo Then
										CurSegment = "AP"; 
									//THEY MADE A KIND OF CIRCLE	
									ElsIf POTransition=0 Then
										POTransition=POTransition+1;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
						
					EndIf;
												 	
					//IF THERE ARE MORE PURCHASES THAN NECESSARY IN THE PERSPECTIVE (I.E. THE CLIENT TURNED OUT TO BE IN THE RIGHT ONES)
					//, THEN WE CHECK WHERE WE GO ACCORDING TO THE RIGHT ONES					
					If ColvoShopping > Filters.PurchasesArePromisingUpTo Then 
							
						//IF PURCHASES ARE STILL ONLY THE LOWER THRESHOLD OF CORRECT
						//THEN WE CHECK WHERE WE WERE IN PERSPECT AND WHERE WE GO ACCORDING TO THE RIGHT ONES
						If ColvoShopping = Filters.PurchasesAreCorrect+1 Then		
							//Let's find out where we switched from 
							//IF YOU WERE IN THE AP TRANSITION AB
							If DaysFromDateOfPurchase_ < Filters.ActiveProspectiveUpTo Then 
								TransitionAB = TransitionAB+1;										
							//IF YOU WERE IN THE PO, GO TO THE PO
							ElsIf DaysFromDateOfPurchase_ >= Filters.ActiveProspectiveUpTo And DaysFromDateOfPurchase_ <= Filters.FallingAsleepPromisingUpTo Then
									ZPAVTransition = ZPAVTransition+1;
							//IF YOU WERE IN A JOINT VENTURE THEN THE TRANSITION IS SPAV
							ElsIf DaysFromDateOfPurchase_ > Filters.FallingAsleepPromisingUpTo Then
							     SPAVTransition = SPAVTransition+1;
							EndIf;					
								
							//IN ANY CASE, IF WE HAVE MOVED, WE FIND OURSELVES IN AB (AT THE TOP)AND FROM THERE ONLY THE WAY DOWN
							//WE CHECK WHETHER THEY HAVE GONE DOWN THE RIGHT ONES
							If DaysFromPurchase >= Filters.ActiveLoyalTo Then
								ZvTransition = ZvTransition+1;
								//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
								If DaysFromPurchase > Filters.FallingAsleepFaithfulTo Then
									SVTransition = SVTransition+1;
									CurSegment = "SV";
								Else
									CurSegment = "ZV_";
								EndIf;
							Else
								CurSegment = "AV";
							EndIf;
								
						//IF THERE ARE ALREADY MORE PURCHASES THAN THE LOWER THRESHOLD, THEN WE CHECK WHERE WE WERE AND WHERE WE GO ACCORDING TO THE CORRECT ONES	
						Else
							//Let's find out where we switched from 
							//IF YOU WERE IN THE AB, CHECK IF YOU WENT DOWN
							If DaysFromDateOfPurchase_ < Filters.ActiveLoyalTo Then
								//IF THE DAYS SINCE THE LAST PURCHASE ARE MORE THAN NECESSARY FOR AB, THEN DOWN
								If DaysFromPurchase >= Filters.ActiveLoyalTo Then
									ZvTransition = ZvTransition+1;
									//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
									If DaysFromPurchase > Filters.FallingAsleepFaithfulTo Then
										SVTransition = SVTransition+1;
										CurSegment = "SV";
									Else 
										CurSegment = "ZV_";
									EndIf;
								EndIf;
							//IF THEY WERE IN THE RANKS, WE CHECK WHETHER THEY WENT DOWN OR UP	 
							ElsIf DaysFromDateOfPurchase_ >= Filters.ActiveLoyalTo And DaysFromDateOfPurchase_ <=  Filters.FallingAsleepFaithfulTo Then
								//IF THERE ARE MORE DAYS SINCE THE LAST PURCHASE THAN IT IS NECESSARY FOR ZV, THEN DOWN
								If DaysFromPurchase > Filters.FallingAsleepFaithfulTo Then
						        	SVTransition = SVTransition+1;
									CurSegment = "SV";
								//IF THE DAYS SINCE THE LAST PURCHASE ARE LESS THAN NECESSARY THAN NECESSARY FOR THE ZV THEN UP	 
								ElsIf DaysFromPurchase < Filters.ActiveLoyalTo Then
									ZVAVTransition = ZVAVTransition +1;
									CurSegment = "AV";
								EndIf;
							//IF YOU WERE IN THE SV, WE CHECK WHETHER YOU WENT TO THE TOP		
							ElsIf DaysFromDateOfPurchase_ > Filters. FallingAsleepFaithfulTo Then
								//IF THE DAYS FROM THE LAST PURCHASE ARE LESS THAN NECESSARY FOR SV, THEN UP
								If DaysFromPurchase <= Filters.FallingAsleepFaithfulTo Then
									SVAVTransition = SVAVTransition +1;
									CurSegment = "ZV_";
									//CLARIFYING THE FINAL SEGMENT
									If DaysFromPurchase < Filters.ActiveLoyalTo Then
										CurSegment = "AV";
									ElsIf ZvTransition=0 Then
										ZvTransition=ZvTransition+1;
									EndIf;
								EndIf;
							EndIf;			
						EndIf;
							
					EndIf;
				//WE REMEMBER THE DATE OF THE CURRENT PURCHASE (BUT "LAST" FOR THE NEXT PURCHASE)
				DateOfLastPurchase_ = SamplePeriodPurchase.CurPurchaseDate;
				EndDo;
					
			//WE DETERMINE IN WHICH SEGMENT THE CLIENT STILL REMAINED AT THE END OF THE PERIOD
			If CurSegment = "AN" Then
				ActiveNew.Add(SamplePeriod.Partner, SamplePeriod.Partner);
				RevenueNew = RevenueNew + SamplePeriod.RevenueAmountTurnover;
			ElsIf CurSegment = "AP" Then
				ActiveProspects.Add(SamplePeriod.Partner, SamplePeriod.Partner);
				RevenueProspects = RevenueProspects + SamplePeriod.RevenueAmountTurnover;
			ElsIf CurSegment = "AV" Then
				ActiveFaithful.Add(SamplePeriod.Partner,SamplePeriod.Partner);
				RevenueFaithful = RevenueFaithful + SamplePeriod.RevenueAmountTurnover;
			ElsIf CurSegment = "ZN" Then
				FallingAsleepNew.Add(SamplePeriod.Partner,SamplePeriod.Partner);
			ElsIf CurSegment = "SN" Then
				SleepingNew.Add(SamplePeriod.Partner, SamplePeriod.Partner);
			ElsIf CurSegment = "WP" Then
				FallingAsleepProspects.Add(SamplePeriod.Partner,SamplePeriod.Partner);
			ElsIf CurSegment = "SP" Then
				SleepingProspectsList.Add(SamplePeriod.Partner, SamplePeriod.Partner);
		    ElsIf CurSegment = "ZV_" Then
				SleepingFaithful_.Add(SamplePeriod.Partner,SamplePeriod.Partner);
			ElsIf CurSegment = "SV" Then
				SleepingFaithfulList.Add(SamplePeriod.Partner,SamplePeriod.Partner);
			EndIf;
		EndDo;				  
			
		//NOW WE GO THE OTHER WAY AROUND - WE ARE LOOKING FOR THOSE WHO MADE A PURCHASE BEFORE THE SPECIFIED PERIOD
		SamplePeriod.Reset();
		Selection.Reset();
			
		While Selection.Next() Do
			//IF THE CLIENT IS FOUND IN THE SAMPLE FOR THE SPECIFIED PERIOD, THEN WE HAVE ALREADY DONE ALL THE CALCULATIONS FOR HIM
			SamplePeriod.Reset();
			If SamplePeriod.FindNext(New Structure("Partner",Selection.Partner)) Then
				Continue;
			//IF THE CLIENT IS NOT FOUND, IT MEANS THERE HAVE BEEN NO NEW PURCHASES, HE HAS NOT YET BEEN ACCOUNTED FOR
			//SINCE THERE WERE NO NEW PURCHASES DURING THE SPECIFIED PERIOD
			//IT TURNS OUT THAT THESE CLIENTS COULD ONLY MOVE DOWN
			Else			
				DaysFromDateOfPurchase_ = (BegOfDay(Filters.BeginningDateOfPeriod)-(BegOfDay(Selection.DateOfLastPurchase)))/(60 * 60 * 24); 						
				DaysFromPurchase = (BegOfDay(Filters.EndingDateOfPeriod)-(BegOfDay(Selection.DateOfLastPurchase)))/(60 * 60 * 24); 						

				//IF THERE IS 1 PURCHASE (I.E. THE CUSTOMER IS IN NEW ONES) 
				//, THEN WE CHECK WHERE THEY WERE AND WHETHER THEY WENT DOWN 		
				If Selection.Recorder = 1 Then
					
					//IF YOU WERE IN THE AN, CHECK IF YOU WENT DOWN
					If DaysFromDateOfPurchase_ < Filters.ActiveUpTo Then
						//IF THE DAYS SINCE THE LAST PURCHASE ARE MORE THAN NECESSARY FOR AN, THEN DOWN
						If DaysFromPurchase >= Filters.ActiveUpTo Then
							ZNTransition = ZNTransition+1;
							//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
							If DaysFromPurchase > Filters.FallingAsleepBefore Then
								TransitionCH = TransitionCH+1;
								SleepingNew.Add(Selection.Partner, Selection.Partner);
							Else
								FallingAsleepNew.Add(Selection.Partner,Selection.Partner);
							EndIf;
						Else
							ActiveNew.Add(Selection.Partner, Selection.Partner);
						EndIf;
		             //IF YOU WERE IN THE ZN, CHECK WHETHER YOU WENT DOWN	 
					ElsIf DaysFromDateOfPurchase_ >= Filters.ActiveUpTo And DaysFromDateOfPurchase_ <= Filters.FallingAsleepBefore Then
						//IF THE DAYS SINCE THE LAST PURCHASE ARE MORE THAN NECESSARY FOR ZN, THEN DOWN
						If DaysFromPurchase > Filters.FallingAsleepBefore Then
							TransitionCH = TransitionCH+1;
							SleepingNew.Add(Selection.Partner, Selection.Partner);	 
						Else
							FallingAsleepNew.Add(Selection.Partner,Selection.Partner);
						EndIf;
					//IF WE WERE IN THE CH, THEN WE STAY THERE.
					ElsIf DaysFromDateOfPurchase_ > Filters.FallingAsleepBefore Then	
						If DaysFromPurchase > Filters.FallingAsleepBefore Then
							SleepingNew.Add(Selection.Partner, Selection.Partner);
						EndIf;
					EndIf;	
				EndIf;
								
				//IF THERE IS MORE THAN ONE PURCHASE, BUT NOT MORE THAN IN PERSPECT (I.E. THE CUSTOMER IN PERSPECT)
				//SO WE CHECK WHERE THEY WERE AND WHETHER THEY WENT DOWN
				If Selection.Recorder >= 2 And Selection.Recorder <=  Filters.PurchasesArePromisingUpTo Then
					
					//IF YOU WERE IN THE AP, WE CHECK WHETHER YOU WENT DOWN
					If DaysFromDateOfPurchase_ < Filters.ActiveProspectiveUpTo Then
						//IF THE DAYS SINCE THE LAST PURCHASE ARE MORE THAN NECESSARY FOR THE AP THEN DOWN
						If DaysFromPurchase >= Filters.ActiveProspectiveUpTo Then
							POTransition = POTransition+1;
							//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
							If DaysFromPurchase > Filters.FallingAsleepPromisingUpTo Then
								SPTransition = SPTransition+1;
								SleepingProspectsList.Add(Selection.Partner, Selection.Partner);
							Else
								FallingAsleepProspects.Add(Selection.Partner,Selection.Partner);
							EndIf;
						Else
							ActiveProspects.Add(Selection.Partner, Selection.Partner);
						EndIf;
		             //IF YOU WERE IN THE PO, WE CHECK WHETHER YOU WENT DOWN	 
					ElsIf DaysFromDateOfPurchase_ >= Filters.ActiveProspectiveUpTo And DaysFromDateOfPurchase_ <=  Filters.FallingAsleepPromisingUpTo Then
						//IF THERE ARE MORE DAYS SINCE THE LAST PURCHASE THAN NECESSARY FOR THE PO, THEN DOWN
						If DaysFromPurchase > Filters.FallingAsleepPromisingUpTo Then
						  	SPTransition = SPTransition+1;
							SleepingProspectsList.Add(Selection.Partner, Selection.Partner);	 
						Else
							FallingAsleepProspects.Add(Selection.Partner,Selection.Partner);
						EndIf;
					//IF WE WERE IN THE JOINT VENTURE, THEN WE STAY THERE.
					ElsIf DaysFromDateOfPurchase_ > Filters.FallingAsleepPromisingUpTo Then	
						If DaysFromPurchase > Filters.FallingAsleepPromisingUpTo Then
							SleepingProspectsList.Add(Selection.Partner, Selection.Partner);
						EndIf;
					EndIf;	
							
				EndIf;
									
				//IF THERE ARE MORE PURCHASES THAN NECESSARY IN THE PERSPECTIVE (I.E. THE CLIENT IS IN THE RIGHT ONES)
				//, THEN WE CHECK WHERE THEY WERE AND WHETHER THEY WENT DOWN						
				If Selection.Recorder >=  Filters.PurchasesArePromisingUpTo Then
					
					//IF YOU WERE IN THE AB, CHECK IF YOU WENT DOWN
					If DaysFromDateOfPurchase_ < Filters.ActiveLoyalTo Then
						//IF THE DAYS SINCE THE LAST PURCHASE ARE MORE THAN NECESSARY FOR AB, THEN DOWN
						If DaysFromPurchase >= Filters.ActiveLoyalTo Then 
							ZvTransition = ZvTransition+1;
							//IF THEY HAVE GONE DOWN, CHECK IF THEY HAVE GONE DOWN YET
							If DaysFromPurchase > Filters.FallingAsleepFaithfulTo Then
								SVTransition = SVTransition +1;
								SleepingFaithfulList.Add(Selection.Partner, Selection.Partner);
							Else
								SleepingFaithful_.Add(Selection.Partner,Selection.Partner);
							EndIf;
						Else
							ActiveProspects.Add(Selection.Partner, Selection.Partner);
						EndIf;
		             //IF THEY WERE IN THE RANKS, WE CHECK WHETHER THEY WENT DOWN	 
					ElsIf DaysFromDateOfPurchase_ >= Filters.ActiveLoyalTo And DaysFromDateOfPurchase_ <=  Filters.FallingAsleepFaithfulTo Then
						//IF THERE ARE MORE DAYS SINCE THE LAST PURCHASE THAN IT IS NECESSARY FOR ZV, THEN DOWN
						If DaysFromPurchase > Filters.FallingAsleepFaithfulTo Then
						  	SVTransition = SVTransition+1;
							SleepingFaithfulList.Add(Selection.Partner, Selection.Partner);	 
						Else
							SleepingFaithful_.Add(Selection.Partner,Selection.Partner);
						EndIf;
					//IF WE WERE IN ST. PETERSBURG, WE STAY THERE.
					ElsIf DaysFromDateOfPurchase_ > Filters.FallingAsleepFaithfulTo Then	
						If DaysFromPurchase > Filters.FallingAsleepFaithfulTo Then
							SleepingFaithfulList.Add(Selection.Partner, Selection.Partner);
						EndIf;
					EndIf;	
									
				EndIf;			
			EndIf;
		EndDo;	
	Else
		//Calculating segments
		Selection.Reset();
		
		While Selection.Next() Do
							
			DaysFromPurchase = (BegOfDay(CurrentSessionDate())-(BegOfDay(Selection.DateOfLastPurchase)))/(60 * 60 * 24); 						
		
			//Filling in the segments
			//New
			If Selection.Recorder = 1 Then
							
				//We fill in the active ones
				If DaysFromPurchase < Filters.ActiveUpTo Then
					ActiveNew.Add(Selection.Partner, Selection.Partner);
				EndIf;
							
				//Filling in the falling asleep
				If DaysFromPurchase >= Filters.ActiveUpTo And DaysFromPurchase <=  Filters.FallingAsleepBefore Then
					FallingAsleepNew.Add(Selection.Partner,Selection.Partner);
				EndIf;
					
				//Filling in the sleepers
				If DaysFromPurchase > Filters.FallingAsleepBefore Then
					SleepingNew.Add(Selection.Partner, Selection.Partner);
				EndIf;

			//Promising
			ElsIf Selection.Recorder >= 2 And Selection.Recorder <=  Filters.PurchasesArePromisingUpTo Then
							
				//We fill in the active ones
				If DaysFromPurchase < Filters.ActiveProspectiveUpTo Then
					ActiveProspects.Add(Selection.Partner, Selection.Partner);
				EndIf;
							
				//Filling in the falling asleep
				If DaysFromPurchase >= Filters.ActiveProspectiveUpTo And DaysFromPurchase <=  Filters.FallingAsleepPromisingUpTo Then
					FallingAsleepProspects.Add(Selection.Partner,Selection.Partner);
				EndIf;
							
				//Filling in the sleepers
				If DaysFromPurchase > Filters.FallingAsleepPromisingUpTo Then
					SleepingProspectsList.Add(Selection.Partner, Selection.Partner);
				EndIf;
							
			//Right	
			ElsIf Selection.Recorder >=  Filters.PurchasesArePromisingUpTo Then
							
				//We fill in the active ones
				If DaysFromPurchase < Filters.ActiveLoyalTo Then
					ActiveFaithful.Add(Selection.Partner,Selection.Partner);
				EndIf;
						
				//Filling in the falling asleep
				If DaysFromPurchase >= Filters.ActiveLoyalTo And DaysFromPurchase <=  Filters.FallingAsleepFaithfulTo Then
					SleepingFaithful_.Add(Selection.Partner,Selection.Partner);
				EndIf;
						
				//Filling in the sleepers
				If DaysFromPurchase > Filters.FallingAsleepFaithfulTo Then
					SleepingFaithfulList.Add(Selection.Partner,Selection.Partner);
				EndIf;
						
			EndIf;	
		EndDo;			
	EndIf;

	SegmentTransitions = New Structure();
	SegmentTransitions.Insert("FirstPurchase",FirstPurchase);
	
	SegmentTransitions.Insert("ActiveNewBeginnings",ActiveNewBeginnings);
	SegmentTransitions.Insert("FallingAsleepNewBeginnings",FallingAsleepNewBeginnings);
	SegmentTransitions.Insert("SleepingNewBeginnings",SleepingNewBeginnings);
	SegmentTransitions.Insert("ActivePromisingCompanies",ActivePromisingCompanies);
	SegmentTransitions.Insert("FallingAsleepPromisingStart",FallingAsleepPromisingStart);
	SegmentTransitions.Insert("SleepingProspectsStartList",SleepingProspectsStartList);
	SegmentTransitions.Insert("ActiveLoyalFriends",ActiveLoyalFriends);
	SegmentTransitions.Insert("FallingAsleepFaithfulBeginnings",FallingAsleepFaithfulBeginnings);
	SegmentTransitions.Insert("SleepingFaithfulListBeginning",SleepingFaithfulListBeginning);
	
	SegmentTransitions.Insert("ActiveNew",ActiveNew);
	SegmentTransitions.Insert("FallingAsleepNew",FallingAsleepNew);
	SegmentTransitions.Insert("SleepingNew",SleepingNew);
	SegmentTransitions.Insert("ActiveProspects",ActiveProspects);
	SegmentTransitions.Insert("FallingAsleepProspects",FallingAsleepProspects);
	SegmentTransitions.Insert("SleepingProspectsList",SleepingProspectsList);
	SegmentTransitions.Insert("ActiveFaithful",ActiveFaithful);
	SegmentTransitions.Insert("SleepingFaithful_",SleepingFaithful_);
	SegmentTransitions.Insert("SleepingFaithfulList",SleepingFaithfulList);

	SegmentTransitions.Insert("RevenueNew",RevenueNew);
	SegmentTransitions.Insert("RevenueProspects",RevenueProspects);
	SegmentTransitions.Insert("RevenueFaithful",RevenueFaithful);

	SegmentTransitions.Insert("APTransition",APTransition);
	SegmentTransitions.Insert("TransitionAB",TransitionAB);
	SegmentTransitions.Insert("ZNTransition",ZNTransition);
	SegmentTransitions.Insert("TransitionCH",TransitionCH);
	SegmentTransitions.Insert("ZNAPTransition",ZNAPTransition);
	SegmentTransitions.Insert("SNAPTransition",SNAPTransition);
	SegmentTransitions.Insert("POTransition",POTransition);
	SegmentTransitions.Insert("SPTransition",SPTransition);
	SegmentTransitions.Insert("PoTransition_",PoTransition_);
	SegmentTransitions.Insert("SPAPTransition",SPAPTransition);
	SegmentTransitions.Insert("ZPAVTransition",ZPAVTransition);
	SegmentTransitions.Insert("SPAVTransition",SPAVTransition);
	SegmentTransitions.Insert("ZvTransition",ZvTransition);
	SegmentTransitions.Insert("SVTransition",SVTransition);
	SegmentTransitions.Insert("ZVAVTransition",ZVAVTransition);
	SegmentTransitions.Insert("SVAVTransition",SVAVTransition);
	
 	PutToTempStorage(SegmentTransitions,StorageAddress);
	
EndProcedure

Procedure FillInListOfClients(Parameters, StorageAddress) Export
	
	ListOfClients = New ValueTable;
	ListOfClients.Columns.Add("Client");
	ListOfClients.Columns.Add("ClientManager");
	ListOfClients.Columns.Add("DateOfPurchase");
	ListOfClients.Columns.Add("ColvoShopping");
	ListOfClients.Columns.Add("AmountOfPurchases");
	ListOfClients.Columns.Add("ColvoPurchasesTotal");
	ListOfClients.Columns.Add("TotalPurchases");
	ListOfClients.Columns.Add("EAddress");
	ListOfClients.Columns.Add("Phone");

	Query = New Query(
						"SELECT ALLOWED DISTINCT
						|	Segments.Partner AS Partner
						|INTO SelectionByPartnerSegment
						|FROM
						|	InformationRegister.SegmentPartners AS Segments
						|WHERE
						|	Segments.Segment = &CustomerSegment
						|
						|INDEX BY
						|	Partner
						|;
						|
						|////////////////////////////////////////////////////////////////////////////////
						|SELECT ALLOWED DISTINCT
						|	Segments.Products AS Products
						|INTO SelectionByProductSegment
						|FROM
						|	InformationRegister.SegmentProducts AS Segments
						|WHERE
						|	Segments.Segment = &ProductSegment
						|
						|INDEX BY
						|	Products
						|;
						|
						|////////////////////////////////////////////////////////////////////////////////
						|SELECT ALLOWED DISTINCT
						|	Sales.AccountingDimensionByPartners.Partner AS Partner,
						|	MAX(Sales.SecondPeriod) AS SecondPeriod,
						|	SUM(Sales.RevenueAmountTurnover) AS RevenueAmountTurnover,
						|	COUNT(DISTINCT Sales.Recorder) AS Recorder
						|FROM
						|	AccumulationRegister.RevenueAndCOGS.Turnovers(
						|			&BeginOfPeriod,
						|			&EndOfPeriod,
						|			Auto,
						|			(NOT &ProductSelectionIsUsed_
						|				OR ItemsLocationAttributes.Products = &Products)
						|				AND (NOT &FilterByPartnerSegmentIsUsed
						|					OR AccountingDimensionByPartners.Partner IN
						|						(SELECT
						|							SelectionByPartnerSegment.Partner
						|						FROM
						|							SelectionByPartnerSegment))
						|				AND (NOT &FilterByProductSegmentIsUsed
						|					OR ItemsLocationAttributes.Products IN
						|						(SELECT
						|							SelectionByProductSegment.Products
						|						FROM
						|							SelectionByProductSegment))
						|				AND (NOT &ManagerSelectionIsUsed
						|					OR Manager = &Manager)
						|				AND AccountingDimensionByPartners.Partner IN (&SegmentList)) AS Sales
						|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
						|		ON Sales.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
						|WHERE
						|	(NOT &OrganizationSelectionIsUsed
						|			OR DimensionKeysOfAccountingByPartners.Organization = &Organization)
						|	AND (NOT &SelectionBasedOnAmountOfPurchasesIsUsed
						|			OR Sales.RevenueAmountTurnover > &AmountOfPurchases)
						|	AND Sales.RevenueAmountTurnover > 0
						|GROUP BY
						|	Sales.AccountingDimensionByPartners.Partner");
	//Installing selections

	Query.SetParameter("SegmentList",Parameters.DecryptionList);

	Query.SetParameter("ProductSelectionIsUsed_",Parameters.NomenclatureUsage);
	Query.SetParameter("OrganizationSelectionIsUsed",Parameters.OrganizationUsage);
	Query.SetParameter("SelectionBasedOnAmountOfPurchasesIsUsed",Parameters.PurchaseAmountUsage);
	Query.SetParameter("FilterByProductSegmentIsUsed",Parameters.ItemSegmentUsage);
	Query.SetParameter("ManagerSelectionIsUsed",Parameters.ManagerUsage);
	Query.SetParameter("FilterByPartnerSegmentIsUsed",Parameters.CustomerSegmentUsage);
	Query.SetParameter("ProductSegment",Parameters.ProductSegment);
	Query.SetParameter("CustomerSegment",Parameters.CustomerSegment);
	Query.SetParameter("Products",Parameters.Products);
	Query.SetParameter("Organization",Parameters.Organization);
	Query.SetParameter("AmountOfPurchases",Parameters.AmountOfPurchases);
	Query.SetParameter("Manager",Parameters.Manager);
	
	If Parameters.PeriodOfUse Then
		Query.SetParameter("BeginOfPeriod",BegOfDay(Date('00010101000000')));
		Query.SetParameter("EndOfPeriod",EndOfDay(Parameters.EndingDateOfPeriod));
		Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
		
		Query.SetParameter("BeginOfPeriod",BegOfDay(Parameters.BeginningDateOfPeriod));
		Query.SetParameter("EndOfPeriod",EndOfDay(Parameters.EndingDateOfPeriod));
		SamplePeriod = Query.Execute().Select(QueryResultIteration.ByGroups);
	Else
		Query.SetParameter("BeginOfPeriod",BegOfDay(Date('00010101000000')));
		Query.SetParameter("EndOfPeriod",EndOfDay(CurrentSessionDate()));
		Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
		SamplePeriod = Query.Execute().Select(QueryResultIteration.ByGroups);
	EndIf;
		
	//Fill in the table
	While Selection.Next() Do
		String = ListOfClients.Add();
		String.Client = Selection.Partner;
		String.ClientManager = Selection.Partner.MainManager;
		String.DateOfPurchase = Selection.SecondPeriod;
		SamplePeriod.Reset();
		If SamplePeriod.FindNext(New Structure("Partner",Selection.Partner)) Then
			String.ColvoShopping = SamplePeriod.Recorder;
			String.AmountOfPurchases = SamplePeriod.RevenueAmountTurnover;
		Else
			String.ColvoShopping = 0;
			String.AmountOfPurchases = 0;
		EndIf;
		String.ColvoPurchasesTotal = Selection.Recorder;
		If String.ColvoPurchasesTotal = String.ColvoShopping Then
			 String.TotalPurchases = String.AmountOfPurchases;
		 Else
			 String.TotalPurchases = Selection.RevenueAmountTurnover;
		EndIf;
		String.EAddress = "";
		String.Phone = "";
		For Each Contact In Selection.Partner.ContactInformation Do
			If Contact.EMAddress <> "" Then 
				String.EAddress = TrimL(String.EAddress)+Contact.Presentation+Chars.LF;
			ElsIf Contact.PhoneNumber <> "" Then
				String.Phone = TrimL(String.Phone)+Contact.Presentation+Chars.LF;;
			EndIf;
		EndDo;
	EndDo;

	Parameters.Insert("ListOfClients",ListOfClients);
	PutToTempStorage(Parameters, StorageAddress);

EndProcedure

Procedure FillInShoppingList(Parameters, StorageAddress) Export
	
	ShoppingList = New ValueTable;
	ShoppingList.Columns.Add("Document");
	ShoppingList.Columns.Add("Sum");

	Query = New Query(
						"SELECT ALLOWED DISTINCT
						|	Segments.Partner AS Partner
						|INTO SelectionByPartnerSegment
						|FROM
						|	InformationRegister.SegmentPartners AS Segments
						|WHERE
						|	Segments.Segment = &CustomerSegment
						|
						|INDEX BY
						|	Partner
						|;
						|
						|////////////////////////////////////////////////////////////////////////////////
						|SELECT ALLOWED DISTINCT
						|	Segments.Products AS Products
						|INTO SelectionByProductSegment
						|FROM
						|	InformationRegister.SegmentProducts AS Segments
						|WHERE
						|	Segments.Segment = &ProductSegment
						|
						|INDEX BY
						|	Products
						|;
						|
						|////////////////////////////////////////////////////////////////////////////////
						|SELECT ALLOWED DISTINCT
						|	Sales.RevenueAmountTurnover AS RevenueAmountTurnover,
						|	Sales.Recorder AS Recorder
						|FROM
						|	AccumulationRegister.RevenueAndCOGS.Turnovers(
						|			&BeginOfPeriod,
						|			&EndOfPeriod,
						|			Auto,
						|			(NOT &ProductSelectionIsUsed_
						|				OR ItemsLocationAttributes.Products = &Products)
						|				AND (NOT &FilterByPartnerSegmentIsUsed
						|					OR AccountingDimensionByPartners.Partner IN
						|						(SELECT
						|							SelectionByPartnerSegment.Partner
						|						FROM
						|							SelectionByPartnerSegment))
						|				AND (NOT &FilterByProductSegmentIsUsed
						|					OR ItemsLocationAttributes.Products IN
						|						(SELECT
						|							SelectionByProductSegment.Products
						|						FROM
						|							SelectionByProductSegment))
						|				AND (NOT &ManagerSelectionIsUsed
						|					OR Manager = &Manager)
						|				AND AccountingDimensionByPartners.Partner = &Client) AS Sales
						|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
						|		ON Sales.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
						|WHERE
						|	(NOT &OrganizationSelectionIsUsed
						|			OR DimensionKeysOfAccountingByPartners.Organization = &Organization)
						|	AND (NOT &SelectionBasedOnAmountOfPurchasesIsUsed
						|			OR Sales.RevenueAmountTurnover > &AmountOfPurchases)
						|	AND Sales.RevenueAmountTurnover > 0
						|TOTALS
						|	SUM(RevenueAmountTurnover)
						|BY
						|	OVERALL");
	//Installing selections

	Query.SetParameter("ProductSelectionIsUsed_",Parameters.NomenclatureUsage);
	Query.SetParameter("OrganizationSelectionIsUsed",Parameters.OrganizationUsage);
	Query.SetParameter("SelectionBasedOnAmountOfPurchasesIsUsed",Parameters.PurchaseAmountUsage);
	Query.SetParameter("FilterByProductSegmentIsUsed",Parameters.ItemSegmentUsage);
	Query.SetParameter("ManagerSelectionIsUsed",Parameters.ManagerUsage);
	Query.SetParameter("FilterByPartnerSegmentIsUsed",Parameters.CustomerSegmentUsage);
	Query.SetParameter("ProductSegment",Parameters.ProductSegment);
	Query.SetParameter("CustomerSegment",Parameters.CustomerSegment);
	Query.SetParameter("Products",Parameters.Products);
	Query.SetParameter("Organization",Parameters.Organization);
	Query.SetParameter("AmountOfPurchases",Parameters.AmountOfPurchases);
	Query.SetParameter("Manager",Parameters.Manager);
	Query.SetParameter("Client",Parameters.Client);
	
	If Parameters.PeriodOfUse Then
		If Parameters.TypeOfPurchase = "ColvoShopping" Then
			Query.SetParameter("BeginOfPeriod",BegOfDay(Parameters.BeginningDateOfPeriod));
			Query.SetParameter("EndOfPeriod",EndOfDay(Parameters.EndingDateOfPeriod));
			Selection = Query.Execute().Select();
		ElsIf Parameters.TypeOfPurchase = "ColvoPurchasesTotal" Then 
			Query.SetParameter("BeginOfPeriod",BegOfDay(Date('00010101000000')));
			Query.SetParameter("EndOfPeriod",EndOfDay(Parameters.EndingDateOfPeriod));
			Selection = Query.Execute().Select();
		EndIf;
	Else
		Query.SetParameter("BeginOfPeriod",BegOfDay(Date('00010101000000')));
		Query.SetParameter("EndOfPeriod",EndOfDay(CurrentSessionDate()));
		Selection = Query.Execute().Select();
	EndIf;
	
	Selection.Next();
	Total = New Structure("Total",Selection.RevenueAmountTurnover);
	
	//Fill in the table
	While Selection.Next() Do
		String = ShoppingList.Add();
		String.Document = Selection.Recorder;
		String.Sum = Selection.RevenueAmountTurnover;
	EndDo;

	Parameters.Insert("ShoppingList",ShoppingList);
	Parameters.Insert("Total",Total);
	PutToTempStorage(Parameters, StorageAddress);

EndProcedure

#EndIf
