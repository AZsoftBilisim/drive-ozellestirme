
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the text of the hint for the source of the composition of the sets
//
// Parameters:
//  Source - EnumRef.SourcesOfCompositionOfSetsInProduction
// 
// Returns:
//  String - a hint on the source of the composition of the sets.
//
Function HintOnSourceOfCompositionOfSets(Source) Export
	
	ToolTipText =  "";
	RestrictionText = "";
	
	If Source = Enums.SourcesOfCompositionOfSetsInProduction.Specifications Then
		
		ToolTipText   = NStr("vi = 'Danh sách thành phần chi tiết được đặt trong bảng kê chi tiết. Có thể sử dụng tính năng tham số hóa, tạo bộ sản phẩm nhiều cấp.';
							|ru = 'Перечень комплектующих задается в спецификациях. Можно использовать возможности параметризации, создавать многоуровневые наборы комплектующих.';
							|en = 'Specify a component list in bills of materials. You can use parametrization and create multi-level components.'; fa = 'Specify a component list in bills of materials. You can use parametrization and create multi-level components.';
							|it = 'L''elenco di componenti viene impostato nelle specifiche. Con le opzioni di parametrizzazione è possibile creare set di componenti a più livelli.';
							|pl = 'Wykaz komponentów jest określany w specyfikacjach. Można używać możliwości parametryzacji, tworzyć wielopoziomowe zestawy komponentów.';
							|tr = 'Bileşenlerin listesi ürün reçetelerinde belirtilmektedir. Parametrelendirme olanakları kullanabilir, çok seviyeli bileşen kümeleri oluşturulabilir.'");
		RestrictionText = NStr("vi = 'Không hỗ trợ đối với Thẻ lộ trình.';
								|ru = 'Не поддерживается для Маршрутных карт.';
								|en = 'Not supported for route sheets.'; fa = 'Not supported for route sheets.';
								|it = 'Non è supportato per le mappe di percorso.';
								|pl = 'Nie jest obsługiwane dla Kart technologicznych.';
								|tr = 'Rotalar için desteklenmemektedir.'");
		
	ElsIf Source = Enums.SourcesOfCompositionOfSetsInProduction.SpecificationsOrConfigurationOptions Then
		
		ToolTipText   = NStr("vi = 'Khi có bảng kê chi tiết có hiệu lực - thành phần được xác định bởi bảng kê chi tiết, nếu không, thành phần được xác định bởi phương án đóng bộ mặt hàng.';
							|ru = 'При наличии действующей спецификации - состав определяется спецификацией, иначе - вариантом комплектации номенклатуры.';
							|en = 'The content is determined by the bill of materials if there is a valid bill of materials, otherwise, by the item kit configuration.'; fa = 'The content is determined by the bill of materials if there is a valid bill of materials, otherwise, by the item kit configuration.';
							|it = 'In caso di specifica funzionante, la composizione viene definita dalla specifica, o dalla variante di kit di nomenclatura.';
							|pl = 'Jeśli jest istniejąca obowiązująca specyfikacja - skład jest określany przez specyfikację, inaczej - przez wariant kompletacji produktu.';
							|tr = 'Geçerli bir ürün reçetesinin varlığında, içerik ürün reçetesine göre tanımlanmaktadır, aksi takdirde ürün seti öğesi seçeneğiyle tanımlanmaktadır.'");
		RestrictionText = NStr("vi = 'Không hỗ trợ các thành phần đặt trong bảng kê chi tiết đối với Tờ lộ trình.';
								|ru = 'Составы, заданные в спецификациях, не поддерживаются для Маршрутных карт.';
								|en = 'Contents specified in the bills of materials are not supported for route sheets.'; fa = 'Contents specified in the bills of materials are not supported for route sheets.';
								|it = 'Composizioni indicate nelle specifiche non supportate per le mappe di percorso.';
								|pl = 'Składy, podane w specyfikacjach, nie są obsługiwane dla kart technologicznych.';
								|tr = 'Ürün reçetelerinden belirtilen bileşenler, Rotalar için desteklenmemektedir.'");
		
	ElsIf Source = Enums.SourcesOfCompositionOfSetsInProduction.KitConfigurations Then
		
		ToolTipText = NStr("vi = 'Danh sách thành phần chi tiết được đặt trong các phương án đóng gói mặt hàng. Có thể sử dụng phương án đóng gói trong các chứng từ sản xuất và thương mại.';
							|ru = 'Перечень комплектующих задается в вариантах комплектации номенклатуры. Варианты комплектации можно использовать как в производственных, так и в торговых документах.';
							|en = 'Specify a component list in item kit configurations. You can use kit configurations both in production and trade documents.'; fa = 'Specify a component list in item kit configurations. You can use kit configurations both in production and trade documents.';
							|it = 'L''elenco di componenti è impostato nelle opzioni di composizione di articoli. Le opzioni di composizione di articoli possono essere utilizzati sia nei documenti di produzione che in quelli di vendita.';
							|pl = 'Wykaz komponentów jest podawany w wariantach kompletacji produktu. Wariantów kompletacji można używać w dokumentach zarówno produkcyjnych, jak i handlowych';
							|tr = 'Bileşenlerin listesi, öğe ürün seti seçeneklerinde belirtilmektedir. Ürün seti seçenekleri hem üretim hem de satış belgelerinde kullanılabilir.'");
		
	EndIf;
	
	If Not GetFunctionalOption("StoreOperationsInBillsOfMaterials") Then
		ToolTipText = ToolTipText + " " + RestrictionText;
	EndIf;
	Return ToolTipText;
	
EndFunction

// Fills in the selection list of the source of the composition of the set
// 
// Parameters:
//  List - ValueList of EnumRef.SourcesOfCompositionOfSetsInProduction
Procedure FillInListOfSelectionOfSourcesOfCompositionOfSets(List) Export
	
	List.Clear();
	If GetFunctionalOption("UseProductionManagement2_2")
			And Not GetFunctionalOption("UseProductionManagement") Then
		List.Add(Enums.SourcesOfCompositionOfSetsInProduction.Specifications, NStr("vi = 'bảng kê chi tiết';
																					|ru = 'спецификациями';
																					|en = 'bills of materials'; fa = 'bills of materials';
																					|it = 'specifiche';
																					|pl = 'przez specyfikacje';
																					|tr = 'ürün reçeteleri ile'"));
		List.Add(Enums.SourcesOfCompositionOfSetsInProduction.SpecificationsOrConfigurationOptions, NStr("vi = 'bảng kê chi tiết hoặc phương án đóng bộ';
																										|ru = 'спецификациями или вариантами комплектации';
																										|en = 'bills of materials or kit configurations'; fa = 'bills of materials or kit configurations';
																										|it = 'specifiche o varianti di kit';
																										|pl = 'przez specyfikacje lub warianty kompletacji';
																										|tr = 'ürün reçetesi veya ürün seti seçenekleri ile'"));
	EndIf;
	List.Add(Enums.SourcesOfCompositionOfSetsInProduction.KitConfigurations, NStr("vi = 'phương án đóng bộ';
																					|ru = 'вариантами комплектации';
																					|en = 'kit configurations'; fa = 'پیکربندی‌های کیت';
																					|it = 'varianti di kit';
																					|pl = 'przez kompletacje';
																					|tr = 'ürün seti seçenekleri ile'"));
	
EndProcedure

#EndRegion

#EndIf
