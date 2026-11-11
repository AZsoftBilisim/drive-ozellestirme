#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the hint text for the item type
//
// Parameters:
//  ItemsType	 - EnumRef.ItemsTypes	 - the type of item.
// 
// Returns:
//  String - a hint on the type of item.
//
Function ProductTypeHint(ItemsType) Export
	
	If ItemsType = Enums.ItemsTypes.OwnGoods Then
		Return NStr("vi = 'Giá trị vật chất mà doanh nghiệp mua, sản xuất và bán được ghi nhận trong các kho. Có thể kiểm soát số dư trong kho, ghi nhận giá thành, đảm bảo nhu cầu...';
					|ru = 'Материальные ценности, которые закупаются, производятся, реализуются предприятием и учитываются на складах. Возможен контроль остатков на складах, учет себестоимости, обеспечение потребностей и др.';
					|en = 'Tangible assets purchased, produced, sold by the enterprise and recorded in warehouses. It is possible to control stock, keep records of cost, satisfy demands, etc.'; fa = 'Tangible assets purchased, produced, sold by the enterprise and recorded in warehouses. It is possible to control stock, keep records of cost, satisfy demands, etc.';
					|it = 'Beni materiali che vengono acquistati, prodotti, venduti dall''impresa e registrati in contabilità nei magazzini. È possibile effettuare controllo delle eccedenze nei magazzini, contabilità del costo di produzione, copertura del fabbisogno, etc.';
					|pl = 'Wartości materiałowe, które są kupowane, produkowane, sprzedawane przez przedsiębiorstwo i są uwzględniane na magazynach. Możliwa jest kontrola zapasów w magazynach, ewidencja kosztów własnych, zaspokojenie zapotrzebowania, itp.';
					|tr = 'İşletme tarafından satın alınan, üretilen, satılan ve ambarlarda muhasebeleştirilen malzeme değerleri. Stok bakiyelerini, maliyet muhasebesini, talebin karşılanmasını vb. kontrol etmek mümkündür.'");
	ElsIf ItemsType = Enums.ItemsTypes.Set Then
		ToolTipText = NStr("vi = 'Bộ dụng cụ không được lưu trữ trong kho mà được lắp ráp linh hoạt. Được sử dụng để thuận tiện lựa chọn các mặt hàng liên quan trong bán hàng, giá cả và in chứng từ.';
							|ru = 'Комплекты, которые не хранятся на складе, а собираются динамически. Используются для удобного выбора связанных позиций в документах продажи, ценообразовании и печати.';
							|en = 'Sets that are not stored in the warehouse but assembled dynamically. They are used to easily select linked items in sales documents, pricing, and printing.'; fa = 'Sets that are not stored in the warehouse but assembled dynamically. They are used to easily select linked items in sales documents, pricing, and printing.';
							|it = 'Kit che non sono custoditi in magazzino ma vengono assemblati dinamicamente. Sono utilizzati per una selezione comoda delle posizioni collegate nei documenti di vendita, nella formazione dei prezzi e per la stampa.';
							|pl = 'Zestawy, które nie są przechowywane w magazynie, ale są dynamicznie montowane. Służą do łatwego wybierania powiązanych elementów w dokumentach sprzedaży, tworzeniu cen i drukowania.';
							|tr = 'Stokta tutulmayan, ancak dinamik olarak monte edilen setler. Satış, fiyatlandırma ve yazdırma belgelerinde ilgili kalemlerin uygun şekilde seçilmesi için kullanılırlar.'");
		ToolTipText = NStr("vi = 'Bộ dụng cụ không được lưu trữ trong kho mà được lắp ráp linh hoạt. Được sử dụng để thuận tiện lựa chọn các mặt hàng liên quan trong bảng chi tiết theo các nguồn lực sản xuất, chứng từ bán hàng, thiết lập giá và in ấn.';
							|ru = 'Комплекты, которые не хранятся на складе, а собираются динамически. Используются для удобного выбора связанных позиций в ресурсных спецификациях, документах продажи, ценообразовании и печати.';
							|en = 'Sets that are not stored in the warehouse but assembled dynamically. They are used to easily select linked items in bills of materials, sales documents, pricing, and printing.'; fa = 'Sets that are not stored in the warehouse but assembled dynamically. They are used to easily select linked items in bills of materials, sales documents, pricing, and printing.';
							|it = 'Kit che non sono custoditi in magazzino ma vengono assemblati dinamicamente. Sono utilizzati per una selezione comoda delle posizioni collegate nelle specifiche delle risorse, nei documenti di vendita, nella formazione dei prezzi e per la stampa.';
							|pl = 'Zestawy, które nie są przechowywane w magazynie, a zbierają się dynamicznie. Służą do łatwego wybierania powiązanych elementów w źródłowych specyfikacjach, dokumentach sprzedaży, tworzeniu cen i drukowania.';
							|tr = 'Stokta tutulmayan ancak dinamik olarak bir araya getirilen setler. Ürün reçetelerinde, satış belgelerinde, fiyatlandırmada ve yazdırmada ilgili kalemlerin uygun şekilde seçilmesi için kullanılırlar.'");
		Return ToolTipText;
	ElsIf ItemsType = Enums.ItemsTypes.OperationService Then
		Return NStr("vi = 'Giá trị vô hình mà doanh nghiệp mua hoặc bán cho khách hàng. Đối với dịch vụ, không tiến hành kế toán giá thành. Vào thời điểm mua dịch vụ, chỉ ra dạng chi phí mà xác định kế toán chi phí sau này.';
					|ru = 'Нематериальные ценности, которые закупаются предприятием или реализуются клиентам. Для услуг не ведется учет себестоимости. В момент приобретения услуги указывается статья расходов, определяющая дальнейший учет расходов.';
					|en = 'Intangible assets purchased by the enterprise or sold to the customers. There is no cost accounting for services. When a service is purchased, an expense item for accounting purposes is specified.'; fa = 'Intangible assets purchased by the enterprise or sold to the customers. There is no cost accounting for services. When a service is purchased, an expense item for accounting purposes is specified.';
					|it = 'Beni immateriali che vengono acquistati dall''impresa oppure venduti ai clienti. Per i servizi non viene tenuta la contabilità del costo di produzione. Al momento di acquisto del servizio viene indicata la voce di uscita che definisce la ulteriore contabilità delle uscite.';
					|pl = 'Wartości niematerialne, które są nabywane przez przedsiębiorstwo lub są realizowane klientom. Do usług nie jest prowadzona ewidencja kosztów własnych. W momencie zakupu usługi określany jest artykuł wydatków, który określa dalszą ewidencję kosztów.';
					|tr = 'İşletme tarafından satın alınan veya müşterilere satılan maddi olmayan duran varlıklar. Hizmetler için maliyet muhasebesi tutulmamaktadır. Bir hizmet satın alındığında, giderin sonraki muhasebe işlemlerini belirleyen bir gider kalemi muhasebeleştirilir.'");
	ElsIf ItemsType = Enums.ItemsTypes.Work_5 Then
		Return NStr("vi = 'Tài sản cố định vô hình được mua hoặc sản xuất, được bán cho khách hàng và được hạch toán trong bộ phận người nhận. Tiến hành kế toán định lượng và kế toán chi phí.';
					|ru = 'Нематериальные ценности, которые закупаются или производятся, реализуются клиентам и учитываются в подразделении-получателе. Ведется количественный учет и учет себестоимости.';
					|en = 'Intangible assets purchased or produced, sold to customers and recorded in the receiving business unit. Quantitative and cost accounting records are kept.'; fa = 'Intangible assets purchased or produced, sold to customers and recorded in the receiving business unit. Quantitative and cost accounting records are kept.';
					|it = 'Beni immateriali che vengono acquistati o prodotti, venduti ai clienti e registrati in contabilità nel reparto-destinatario. Viene tenuta la contabilità quantitativa e del costo di produzione.';
					|pl = 'Wartości niematerialne, które są nabywane lub wytwarzane, są realizowane klientom i są brane pod uwagę w dziale przeznaczenia. Prowadzona jest ewidencja ilościowa i ewidencji kosztów własnych.';
					|tr = 'Satın alınan veya üretilen maddi olmayan duran varlıklar müşterilere satılır ve alıcı departmanında muhasebeleştirilir. Miktar ve maliyet muhasebesi sürdürülmektedir.'");
	ElsIf ItemsType = Enums.ItemsTypes.ReusablePackage Then
		Return NStr("vi = 'Một bao bì được ghi nhận riêng biệt trong kho và có thể được trả lại hàng hóa cho nhà cung cấp hoặc chuyển khi trả lại cho khách hàng.';
					|ru = 'Тара, которая учитывается отдельно на складе и может возвращаться поставщику товаров или передаваться на условиях возврата клиенту.';
					|en = 'Package recorded separately in a warehouse and can be returned to goods vendor or transferred to a customer according to return terms.'; fa = 'Package recorded separately in a warehouse and can be returned to goods vendor or transferred to a customer according to return terms.';
					|it = 'Imballaggio che viene registrato in contabilità separatamente nel magazzino e può essere restituito al fornitore delle merci oppure consegnato al cliente con la condizione di reso.';
					|pl = 'Tara, która uwzględnia się oddzielnie na magazynie i może wracać do dostawcy towarów lub być przekazywana na warunkach zwrotu klientowi.';
					|tr = 'Ambarda ayrı olarak muhasebeleştirilen ve ürün tedarikçisine iade edilebilen veya müşteriye iade esasına göre aktarılabilen ambalaj.'");
	Else
		Return NStr("vi = 'Xác định tính năng kế toán mặt hàng theo các cơ chế khác nhau';
					|ru = 'Определяет возможности по учету номенклатуры в различных механизмах';
					|en = 'Determines different schemes for accounting of products'; fa = 'Determines different schemes for accounting of products';
					|it = 'Stabilisce la possibilità di registrazione degli articoli con meccanismi diversi';
					|pl = 'Określa możliwości według ilości ewidencyjnej pozycji w różnych mechanizmach';
					|tr = 'Çeşitli mekanizmalarda öğe muhasebesi yeteneklerini tanımlıyor'");
	EndIf;	
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ExcludedValues = New Array;
	
	SeveralKindsOfProducts = GetFunctionalOption("UseMultipleKindsOfProducts");
	
	If Not SeveralKindsOfProducts
		Or Not GetFunctionalOption("UseReusablePackage") Then
		ExcludedValues.Add(Enums.ItemsTypes.ReusablePackage);
	EndIf;
	
	If Not SeveralKindsOfProducts
		Or Not GetFunctionalOption("UseSets") Then
		ExcludedValues.Add(Enums.ItemsTypes.Set);
	EndIf;
	
	If Not SeveralKindsOfProducts
		Or GetFunctionalOption("BaseVersion") Then
		ExcludedValues.Add(Enums.ItemsTypes.Work_5);
	EndIf;
	
	StandardProcessing = False;
	
	SearchParameters = Common.CopyRecursive(Parameters);
	SearchParameters.Insert("SearchStringModeOnInputByString", SearchStringModeOnInputByString.Begin);
	
	TMCommonUse.SelectableEnumerationValues(
		EmptyRef().Metadata().Name,
		ChoiceData,
		SearchParameters,
		ExcludedValues);

EndProcedure

#EndRegion

#EndIf
#EndIf

