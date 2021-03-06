cosy.resource.nodes = {}
cosy.resource.nodes[1] = {}
cosy.resource.nodes[1].position = [[60,-80]]
cosy.resource.nodes[1].type = [[place]]
cosy.resource.nodes[1].marking = true
cosy.resource.nodes[1].name = [[place 1]]
cosy.resource.nodes[2] = {}
cosy.resource.nodes[2].position = [[60:0]]
cosy.resource.nodes[2].type = [[transition]]
cosy.resource.nodes[2].marking = false
cosy.resource.nodes[2].name = [[transition 2]]
cosy.resource.nodes[3] = {}
cosy.resource.nodes[3].position = [[240,190]]
cosy.resource.nodes[3].highlighted = true
cosy.resource.nodes[3].type = [[place]]
cosy.resource.nodes[3].marking = false
cosy.resource.nodes[3].name = [[place 3]]
cosy.resource.nodes[4] = {}
cosy.resource.nodes[4].position = [[60,210]]
cosy.resource.nodes[4].type = [[transition]]
cosy.resource.nodes[4].marking = false
cosy.resource.nodes[4].name = [[transition 4]]
cosy.resource.arcs = {}
cosy.resource.arcs[1] = {}
cosy.resource.arcs[1].arc_1 = {}
cosy.resource.arcs[1].arc_1.source = cosy.resource.nodes[1]
cosy.resource.arcs[1].arc_1.target = cosy.resource.nodes[2]
cosy.resource.arcs[1].arc_1.anchor = [[SE]]
cosy.resource.arcs[1].arc_1.type = [[arc]]
cosy.resource.arcs[1].arc_2 = {}
cosy.resource.arcs[1].arc_2.source = cosy.resource.nodes[2]
cosy.resource.arcs[1].arc_2.target = cosy.resource.nodes[4]
cosy.resource.arcs[1].arc_2.anchor = [[SW]]
cosy.resource.arcs[1].arc_2.lock_pos = true
cosy.resource.arcs[1].arc_2.type = [[arc]]
cosy.resource.arcs[1].arc_3 = {}
cosy.resource.arcs[1].arc_3.source = cosy.resource.nodes[4]
cosy.resource.arcs[1].arc_3.target = cosy.resource.nodes[3]
cosy.resource.arcs[1].arc_3.anchor = [[W]]
cosy.resource.arcs[1].arc_3.type = [[arc]]
