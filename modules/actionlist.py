from flatland.envs.rail_env import RailEnv
from flatland.envs.rail_env import RailEnvActions
from flatland.utils.rendertools import RenderTool, AgentRenderVariant
from modules.convert import convert_actions_to_flatland

def to_dicts(action_list):
    """
    convert a list of actions to a list of action_dicts
    this is more consistent with the structure that flatland accepts
    """
    result = []

    current_time_step = action_list[0][2]
    current_dict = {}

    for agent, command, time_step in action_list:
        if time_step != current_time_step:
            result.append(current_dict)
            current_dict = {}
            current_time_step = time_step
        
        current_dict[agent] = command

    # append the last dictionary after the loop
    result.append(current_dict)

    # replace actions with RailEnvActions
    mapping = {"move_forward":RailEnvActions.MOVE_FORWARD, "move_right":RailEnvActions.MOVE_RIGHT, "move_left":RailEnvActions.MOVE_LEFT, "wait":RailEnvActions.STOP_MOVING}
    return(convert_actions_to_flatland(result))


def build_action_list(models):
    """
    given a model from clingo, build an python action list
    """
    if not models:
        raise ValueError("No solution found: the encoding is unsatisfiable.")
    action_list = []
    for func in models[-1]:  #last model
        func_name = func.name
        if func_name == "action":
            action = func.arguments[1].name
            agent, timestep = func.arguments[0], func.arguments[2]
            agent_num = agent.arguments[0].number
            action_list.append((agent_num,action,timestep.number))

    sorted_list = sorted(action_list, key=lambda x: (x[2], x[0]))   # sorts actions in list by time and agent ID
    return(to_dicts(sorted_list))

def extract_position_atoms(models):
    """
    given a model from clingo, build a python positions list
    """
    # TODO: cast the positions into Python object in order for easier transformations downstream
    position_list = []
    for func in models[-1]: # only the last model
        func_name = func.name
        if func_name == "position":
            agent, position, timestep = func.arguments[0], func.arguments[1], func.arguments[2]
            direction = func.arguments[3].name
            position_list.append((agent,position,timestep,direction))
            
    sorted_list = sorted(position_list, key=lambda x: (x[2], x[0])) # sorts positions by time and agent ID
    #print(sorted_list)
    return sorted_list
