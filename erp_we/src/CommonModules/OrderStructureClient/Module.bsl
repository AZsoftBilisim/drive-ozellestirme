
#Region Public

#Region Other

// If the background structure calculation task is not running, it starts it.
Procedure CheckRunOrderStructureCalculationBackgroundTask() Export
	
	OrderStructureServerCall.CheckRunOrderStructureCalculationBackgroundTask();
	
EndProcedure

// Adds tasks to the recalculation of the production order structure and starts the calculation
// 
// Parameters:
// 	ProductionOrders - Array, DocumentRef.ProductionOrder2_2	- a production order or a list of production orders.
//
Procedure StartRecalculatingOrderStructure(ProductionOrders) Export
	
	OrderStructureServerCall.StartRecalculatingOrderStructure(ProductionOrders);
	ShowUserNotification(NStr("vi = 'Tính toán cấu trúc đơn hàng';
								|ru = 'Расчет структуры заказа';
								|en = 'Order structure calculation'; fa = 'Order structure calculation';
								|it = 'Calcolo della struttura dell''ordine';
								|pl = 'Obliczenie struktury zamówienia';
								|tr = 'Sipariş yapısının hesaplanması'"),, NStr("vi = 'Đã khởi động tính lại nhu cầu về nguyên vật liệu và nguồn lực lao động';
																			|ru = 'Запущен пересчет потребности в материалах и трудовых ресурсах';
																			|en = 'The recalculation of demand for materials and human resources has been started'; fa = 'The recalculation of demand for materials and human resources has been started';
																			|it = 'Ricalcolo dei consumi avviato nei materiali e e risorse di lavoro';
																			|pl = 'Uruchomiono przeliczenie zapotrzebowania w materiałach i zasobach pracy';
																			|tr = 'Malzeme ve işçilik kaynağı taleplerinin yeniden hesaplanması başlatıldı'"), PictureLib.Information32);
	
EndProcedure

// Adds tasks to the calculation of the structure of the production order according to the specification and starts the calculation
// 
// Parameters:
// 	BillOfMaterials			 - CatalogRef.BillsOfMaterials			- specification.
// 	ProductionOrders	 - Array, DocumentRef.ProductionOrder2_2	- a production order or a list of production orders.
//
Procedure StartRecalculatingOrderStructureAccordingToSpecification(BillOfMaterials, ProductionOrders) Export
	
	OrderStructureServerCall.StartRecalculatingOrderStructureAccordingToSpecification(BillOfMaterials, ProductionOrders);
	ShowUserNotification(NStr("vi = 'Tính toán cấu trúc đơn hàng';
								|ru = 'Расчет структуры заказа';
								|en = 'Order structure calculation'; fa = 'Order structure calculation';
								|it = 'Calcolo della struttura dell''ordine';
								|pl = 'Obliczenie struktury zamówienia';
								|tr = 'Sipariş yapısının hesaplanması'"),, NStr("vi = 'Đã khởi động tính lại nguyên vật liệu, công lao động theo bảng kê chi tiết đã chọn';
																			|ru = 'Запущен пересчет материалов, трудозатрат по выбранной спецификации';
																			|en = 'The recalculation of materials and labor costs by the selected bill of materials has been started'; fa = 'The recalculation of materials and labor costs by the selected bill of materials has been started';
																			|it = 'Ricalcolo avviato dei materiali, costi del lavoro per la specifica selezionata';
																			|pl = 'Uruchomiono przeliczenie materiałów, nakładów pracy według wybranej specyfikacji';
																			|tr = 'Seçili ürün reçetesine göre iş gücü maliyetlerinin, malzemelerin yeniden hesaplanması başlatıldı'"), PictureLib.Information32);
	
EndProcedure

#EndRegion

#EndRegion
