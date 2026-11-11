#Region Internal

// Fills in the client's operation parameters on the server
// When using BSP, the procedure must be called from the procedure 
// The general purpose is undefined.Adding the Client's work parameters()
//
// Parameters:
//   Parameters - Structure:
//    * ClientID - String - (incoming) ID of the client's workplace
//    * EquipmentForReinstalling - Array of Structure - names of Templates for reinstalling external components
//    * IdOfDistributedFiscalizationDiscussion - CollaborationSystemConversationID -
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	PELSubsystemsIntegration.OnAddClientParametersOnStart(Parameters);
	
EndProcedure

#EndRegion
