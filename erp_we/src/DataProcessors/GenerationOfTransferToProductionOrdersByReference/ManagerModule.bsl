#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("View", Metadata.DataProcessors.GenerationOfTransferToProductionOrdersByReference) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateProductionTransferOrders";
		CreateBasedOnCommand.Manager = Metadata.DataProcessors.GenerationOfTransferToProductionOrdersByReference.FullName();
		CreateBasedOnCommand.Presentation =  NStr("vi = 'Đơn đề nghị xuất nguyên vật liệu vào sản xuất';
													|ru = 'Заказы материалов в производство';
													|en = 'Material orders for shop floor stockroom'; fa = 'سفارش‌های مواد برای انبار کارگاه';
													|it = 'Ordini dei materiali per la produzione';
													|pl = 'Zamówienia materiałów na produkcje';
													|tr = 'Üretimdeki malzemelerin siparişleri'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProduction";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	Return BOMSelectionParameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "";
	Return AttributesNames;
	
EndFunction

#EndRegion

#EndIf


