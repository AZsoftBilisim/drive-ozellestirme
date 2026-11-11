
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	CurrentSpecification = CommandParameter;
	
	If Not ValueIsFilled(CurrentSpecification) Then
		MessageText = NStr("vi = 'Không thể lập cây bảng kê chi tiết, chưa chọn bảng kê chi tiết.';
							|ru = 'Невозможно сформировать дерево спецификации, спецификация не выбрана.';
							|en = 'Cannot generate a BOM tree, a bill of materials is not selected.'; fa = 'Cannot generate a BOM tree, a bill of materials is not selected.';
							|it = 'Non è possibile creare l''albero delle specifiche, specifica non selezionata.';
							|pl = 'Nie można wygenerować drzewa specyfikacji, nie wybrano specyfikacji.';
							|tr = 'Ürün ağacı oluşturmak mümkün değil, ürün reçetesi seçilmedi.'");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.BillsOfMaterialsTree.Command.BOMTree");
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("BillOfMaterials", CurrentSpecification);
	OpeningParameters.Insert("GenerateOnOpen", True);
	OpeningParameters.Insert("Title", NStr("vi = 'Cây bảng kê chi tiết các nguồn lực sản xuất';
											|ru = 'Дерево спецификации';
											|en = 'BOM tree'; fa = 'درخت فهرست مواد';
											|it = 'Albero della specifica';
											|pl = 'Drzewo specyfikacji';
											|tr = 'Ürün ağacı'")); 
	OpeningParameters.Insert("ViewMode", "BillOfMaterials");
	
	OpenForm("DataProcessor.BillsOfMaterialsTree.Form", OpeningParameters, 
		CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion