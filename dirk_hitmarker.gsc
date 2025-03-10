#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_powerups;
#include maps\mp\gametypes_zm\spawnlogic;
#include maps\mp\gametypes_zm\_hostmigration;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\gametypes_zm\_hud_message;


init()
{
    precacheshader( "damage_feedback" ); 
    level endon( "end_game" );
    level thread onplayerconnect();
}

onplayerconnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onplayerspawned();
    }
}

onplayerspawned()
{
    
    level endon("game_ended");
    self endon("disconnect");
    for(;;)
    {
        self waittill("spawned_player");
        self thread drawdamagehitmarker();
    }
}

drawdamagehitmarker()
{
    self thread startwaiting();
    self.hitmarker = newdamageindicatorhudelem( self );
    self.hitmarker.horzalign = "center";
    self.hitmarker.vertalign = "middle";
    self.hitmarker.x = -12;
    self.hitmarker.y = -12;
    self.hitmarker.alpha = 0;
    self.hitmarker setshader( "damage_feedback", 24, 48 );
}

startwaiting()
{
	while( 1 )
	{
        foreach( zombie in getaiarray( level.zombie_team ) )
        {
            if( !(IsDefined( zombie.waitingfordamage )) )
            {
                zombie thread hitmark();
            }
        }
        wait 0.25;
	}
}

hitmark()
{
	self endon( "killed" );
	self.waitingfordamage = 1;
	while( 1 )
	{
		self waittill( "damage", amount, attacker, dir, point, mod );
		if( isplayer( attacker ) )
		{
			if( isalive( self ) )
			{
				attacker.hitmarker.color = ( 1, 1, 1 );
				attacker.hitmarker.alpha = 1;
				attacker.hitmarker fadeovertime( 1 );
				attacker.hitmarker.alpha = 0;
			}
			else
			{
				attacker.hitmarker.color = ( 1, 0, 0 );
                attacker.hitmarker.alpha = 1;
				attacker.hitmarker fadeovertime( 1 );
				attacker.hitmarker.alpha = 0;
				self notify( "killed" );
			}
		}
	}
}	

updatedamagefeedback( mod, inflictor, death )
{
    if( IsDefined( self.disable_hitmarkers ) || !(isplayer( self )) )
    {
        return;
    }

    if( mod != "MOD_HIT_BY_OBJECT" && mod != "MOD_GRENADE_SPLASH" && mod != "MOD_CRUSH" && IsDefined( mod ) )
    {
        if( death )
        {
            self hud_show_zombie_health(self.targetZombie, true);
        }
        else
        {

        }

        if (IsDefined(self.targetZombie) && isalive(self.targetZombie))
        {
            self hud_show_zombie_health(self.targetZombie, false);
        }
    }
    return 0;
}

do_hitmarker_death()
{
    if( self.attacker != self && isplayer( self.attacker ) && IsDefined( self.attacker ) )
    {
        self.attacker thread updatedamagefeedback( self.damagemod, self.attacker, 1 );
    }
    return 0;
}

do_hitmarker( mod, hitloc, hitorig, player, damage )
{
    if( player != self && isplayer( player ) && IsDefined( player ) )
    {
        player.targetZombie = self;
        player thread updatedamagefeedback( mod, player, 0 );
    }
    return 0;
}

hud_show_zombie_health(zombie, isDead)
{
    self endon("disconnect");
    level endon("end_game");

    if (!isdefined(zombie))
        return;
    if (!isdefined(self.hud_zombie_health))
    {
        self.hud_zombie_health = self createprimaryprogressbar();        
        self.hud_zombie_health setpoint( "RIGHT", "BOTTOM", -75, -13 );
        self.hud_zombie_health.hidewheninmenu = false;

        self thread configbar();

    }

    zombieIndex = -1;
    zombieArray = getaiarray(level.zombie_team);
    for (i = 0; i < zombieArray.size; i++)
    {
        if (zombieArray[i] == zombie)
        {
            zombieIndex = i;
            break;
        }
    }

    if (isDead)
    {
        self.hud_zombie_health updatebar(0);
        self.hud_zombie_health.bar.color = (1, 0.2, 0.2);
    }
    else
    {
        totalHealth = zombie.maxhealth;
        damageInflicted = totalHealth - zombie.health;
        healthFraction = zombie.health / totalHealth;
        healthFractionColor = healthFraction * 100;
        self.hud_zombie_health updatebar(healthFraction);
        if(healthFractionColor <= 100 && healthFractionColor >= 71)
            self.hud_zombie_health.bar.color = (0, 1, 0.5);
        else if(healthFractionColor <= 70 && healthFractionColor >= 50)
            self.hud_zombie_health.bar.color = (1, 1, 0);
        else if(healthFractionColor <= 49 && healthFractionColor >= 25)
            self.hud_zombie_health.bar.color = (1, 0.5, 0);
        else if(healthFractionColor <= 24 && healthFractionColor >= 0)
            self.hud_zombie_health.bar.color = (1, 0.2, 0.2);
    }

    if (!isDead && zombie.health == zombie.maxhealth)
    {
        self.hud_zombie_health fadeovertime(1.5);
        self.hud_zombie_health.alpha = 0;
        wait 1.5;
        self.hud_zombie_health destroy();
        self.hud_zombie_health = undefined;
    }
}

configbar()
{
    self endon("disconnect");
    level endon("end_game");
    while(true)
    {
        self.hud_zombie_health.width = 75; 
        self.hud_zombie_health.height = 3;
        self.hud_zombie_health.alpha = 0;
        if(self.zombiehealthvisible)
            self.hud_zombie_health.bar.alpha = 1;
        else
            self.hud_zombie_health.bar.alpha = 0;
        wait 1;
    }
}
